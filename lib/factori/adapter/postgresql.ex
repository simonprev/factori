defmodule Factori.Adapter.Postgresql do
  require Logger
  alias Factori.Bootstrap

  @columns """
  SELECT
    table_name,
    column_name,
    udt_name,
    is_nullable,
    is_generated,
    character_maximum_length
  FROM
    information_schema.columns
  WHERE
    table_schema NOT in('information_schema', 'pg_catalog')
    AND table_name NOT in('schema_migrations')
  ORDER BY
    table_schema,
    table_name;
  """

  @references """
  SELECT
    constraint_table_usage. "table_name" as target,
    constraint_column_usage. "column_name" as target_column,
    key_column_usage. "table_name" as source,
    key_column_usage. "column_name" as source_column
  FROM
    information_schema.constraint_table_usage
    INNER JOIN information_schema.referential_constraints ON referential_constraints. "constraint_name" = constraint_table_usage. "constraint_name"
    INNER JOIN information_schema.constraint_column_usage ON referential_constraints. "constraint_name" = constraint_column_usage. "constraint_name"
    INNER JOIN information_schema.key_column_usage ON referential_constraints. "constraint_name" = key_column_usage. "constraint_name"
  """

  @enums """
  SELECT
      pg_type.typname AS enum_name,
      pg_enum.enumlabel AS enum_value
  FROM
      pg_type
      JOIN pg_enum ON pg_type.oid = pg_enum.enumtypid
      JOIN pg_catalog.pg_namespace ON pg_namespace.oid = pg_type.typnamespace;
  """

  def warn_on_setup(repo) do
    pool_size = Keyword.get(repo.config(), :pool_size)

    if pool_size && pool_size <= 1 do
      Logger.warning(
        "#{inspect(repo)} :pool_size option should be greater than 1 to allow bootstraping and running tests concurrently, got: #{pool_size}"
      )
    end
  end

  def columns!(repo) do
    references = reference_definitions(repo)
    ecto_schemas = ecto_schemas(repo)
    db_enums = enums_definitions(repo)

    repo
    |> query!(@columns)
    |> Enum.group_by(&List.first/1)
    |> Enum.reduce(%{}, fn {table_name, columns}, acc ->
      references = Map.get(references, table_name, [])

      ecto_schema =
        ecto_schemas
        |> Enum.flat_map(fn {module, table} -> if table == table_name, do: [module], else: [] end)
        |> Enum.sort_by(&String.length(inspect(&1)))
        |> List.first()

      columns =
        columns
        |> Enum.map(&generate_column_definition(&1, references, db_enums, ecto_schema))
        |> Enum.group_by(& &1.name)
        |> Enum.map(fn {name, [definition]} -> {name, definition} end)
        |> Enum.into(%{})
        |> Map.values()

      Map.put(acc, table_name, columns)
    end)
  end

  defp enums_definitions(repo) do
    repo
    |> query!(@enums)
    |> Enum.group_by(&hd(&1), &Enum.at(&1, 1))
    |> Enum.map(fn {enum_value, enum_labels} ->
      %Bootstrap.EnumDefinition{
        name: enum_value,
        mappings: Enum.map(enum_labels, &{String.to_atom(&1), &1})
      }
    end)
  end

  defp reference_definitions(repo) do
    repo
    |> query!(@references)
    |> Enum.map(fn [target, target_column, source, source_column] ->
      %Bootstrap.ReferenceDefinition{
        source: source,
        target: target,
        source_column: String.to_atom(source_column),
        target_column: String.to_atom(target_column)
      }
    end)
    |> Enum.group_by(& &1.source)
  end

  defp generate_column_definition(column, references, db_enums, ecto_schema) do
    [table_name, name, type, null, generated, size] = column
    fields = List.wrap(ecto_schema && ecto_schema.__schema__(:fields))
    embeds = List.wrap(ecto_schema && ecto_schema.__schema__(:embeds))
    identifier = String.to_atom(name)

    ecto_enum =
      with schema when not is_nil(schema) <- ecto_schema,
           true <- identifier in fields,
           {:parameterized, Ecto.Enum, _} <- ecto_schema.__schema__(:type, identifier) do
        %Bootstrap.EnumDefinition{
          name: name,
          mappings: Ecto.Enum.mappings(ecto_schema, identifier)
        }
      else
        _ -> nil
      end

    db_enums =
      if ecto_enum do
        db_enums
        |> Enum.reject(&(&1.name === ecto_enum.name))
        |> Enum.concat([ecto_enum])
      else
        db_enums
      end

    ecto_embed =
      with schema when not is_nil(schema) <- ecto_schema,
           true <- identifier in embeds,
           %Ecto.Embedded{cardinality: cardinality, related: related} <-
             ecto_schema.__schema__(:embed, identifier) do
        %Bootstrap.EmbedDefinition{
          name: name,
          cardinality: cardinality,
          ecto_schema: related
        }
      else
        _ -> nil
      end

    ecto_type =
      if !!ecto_schema && identifier in fields do
        :type
        |> ecto_schema.__schema__(identifier)
        |> assured_atom_or_parameterized_type()
      end

    reference =
      case Enum.find(references, fn reference ->
             {reference.source, reference.source_column} === {table_name, identifier}
           end) do
        %{target: target, target_column: target_column} -> {target, target_column}
        _ -> nil
      end

    enum = Enum.find(db_enums, &(&1.name === type || &1.name === name))
    ecto_type = if type === "uuid", do: Ecto.UUID, else: ecto_type

    %Bootstrap.ColumnDefinition{
      table_name: table_name,
      name: identifier,
      type: type,
      ecto_type: ecto_type,
      ecto_schema: ecto_schema,
      struct_embed: generate_embed_columns(table_name, ecto_embed),
      reference: reference,
      enum: enum,
      options: %{
        null: null === "YES",
        ignore: generated === "ALWAYS",
        size: size
      }
    }
  end

  @spec assured_atom_or_parameterized_type(term()) :: atom() | module()
  defp assured_atom_or_parameterized_type(type) do
    case type do
      type when is_atom(type) -> type
      {:parameterized, type, []} when is_atom(type) -> type
      {:parameterized, {type, []}} when is_atom(type) -> type
      _ -> nil
    end
  end

  defp generate_embed_columns(_, nil), do: nil

  defp generate_embed_columns(table_name, ecto_embed) do
    references =
      Enum.map(ecto_embed.ecto_schema.__schema__(:associations), fn association_name ->
        association = ecto_embed.ecto_schema.__schema__(:association, association_name)

        %Bootstrap.ReferenceDefinition{
          source: table_name,
          source_column: association.owner_key,
          target: association.queryable.__schema__(:source),
          target_column: association.related_key
        }
      end)

    fields =
      for field <- ecto_embed.ecto_schema.__schema__(:fields) do
        field_reference = Enum.find(references, &(&1.source_column === field))

        table_name = if field_reference, do: field_reference.source, else: table_name
        name = to_string(field)
        type = ecto_type_to_embed_value_type(ecto_embed.ecto_schema.__schema__(:type, field))
        nullable = "NO"
        generated = "NO"
        size = nil

        column = [
          table_name,
          name,
          type,
          nullable,
          generated,
          size
        ]

        generate_column_definition(column, List.wrap(field_reference), [], ecto_embed.ecto_schema)
      end

    {ecto_embed.cardinality, ecto_embed.ecto_schema, fields}
  end

  defp ecto_type_to_embed_value_type(type) do
    case type do
      Ecto.UUID -> "uuid"
      :utc_datetime -> "timestamp"
      :naive_datetime -> "timestamp"
      :utc_datetime_usec -> "timestamp"
      :naive_datetime_usec -> "timestamp"
      :boolean -> "bool"
      :float -> "float4"
      :time -> "time"
      :date -> "date"
      :string -> "varchar"
      :integer -> "int4"
      :binary_id -> "varchar"
      :decimal -> "float4"
      {:array, _} -> "array"
      {:map, _} -> "jsonb"
      :map -> "jsonb"
      _ -> "varchar"
    end
  end

  defp ecto_schemas(repo) do
    otp_app = Keyword.get(repo.config(), :otp_app)
    {:ok, modules} = :application.get_key(otp_app, :modules)

    modules
    |> Enum.map(&{&1, schema_module_source(&1)})
    |> Enum.reject(fn {_, source} -> is_nil(source) end)
  end

  def schema_module_source(struct_module) do
    struct_module.__schema__(:source)
  rescue
    UndefinedFunctionError -> nil
  end

  defp query!(repo, query) do
    result = Ecto.Adapters.SQL.query!(repo, query, [])
    result.rows
  end
end
