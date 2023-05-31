defmodule Factori.Adapter.Postgresql do
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

  def columns!(repo) do
    references = reference_definitions(repo)
    ecto_schemas = ecto_schemas(repo)
    db_enums = enums_definitions(repo)

    repo
    |> Bootstrap.query!(@columns)
    |> Enum.group_by(&List.first/1)
    |> Enum.reduce(%{}, fn {table_name, columns}, acc ->
      references = Map.get(references, table_name, [])

      ecto_schema =
        Enum.find_value(ecto_schemas, fn {module, table} -> table == table_name && module end)

      fields = List.wrap(ecto_schema && ecto_schema.__schema__(:fields))

      columns =
        columns
        |> Enum.map(fn [_table, name | _] = column ->
          ecto_enum =
            with schema when not is_nil(schema) <- ecto_schema,
                 identifier = String.to_atom(name),
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

          ecto_type =
            with schema when not is_nil(schema) <- ecto_schema,
                 identifier = String.to_atom(name),
                 true <- identifier in fields,
                 type when is_atom(type) <- ecto_schema.__schema__(:type, identifier) do
              type
            else
              _ -> nil
            end

          generate_column_definition(references, db_enums, column, ecto_schema, ecto_type)
        end)
        |> Enum.group_by(& &1.name)
        |> Enum.map(fn {name, [definition]} -> {name, definition} end)
        |> Enum.into(%{})
        |> Map.values()

      Map.put(acc, table_name, columns)
    end)
  end

  defp enums_definitions(repo) do
    repo
    |> Bootstrap.query!(@enums)
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
    |> Bootstrap.query!(@references)
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

  defp generate_column_definition(
         references,
         db_enums,
         [
           table_name,
           name,
           type,
           null,
           generated,
           size
         ],
         ecto_schema,
         ecto_type
       ) do
    identifier = String.to_atom(name)

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
      reference: reference,
      enum: enum,
      options: %{
        null: null === "YES",
        ignore: generated === "ALWAYS",
        size: size
      }
    }
  end

  defp ecto_schemas(repo) do
    otp_app = Keyword.get(repo.config, :otp_app)
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
end
