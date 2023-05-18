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
    db_enums = enums_definitions(repo)

    schemas = schemas(repo)

    repo
    |> Bootstrap.query!(@columns)
    |> Enum.group_by(&List.first/1)
    |> Enum.reduce(%{}, fn {table_name, columns}, acc ->
      references = Map.get(references, table_name, [])

      ecto_schema =
        Enum.find_value(schemas, fn {module, table} -> table == table_name && module end)

      columns =
        columns
        |> Enum.map(&generate_column_definition(references, ecto_schema, db_enums, &1))
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
        values: enum_labels
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

  defp generate_column_definition(references, schema, db_enums, [
         table_name,
         name,
         type,
         null,
         generated,
         size
       ]) do
    identifier = String.to_atom(name)

    reference =
      case Enum.find(references, fn reference ->
             {reference.source, reference.source_column} === {table_name, identifier}
           end) do
        %{target: target, target_column: target_column} -> {target, target_column}
        _ -> nil
      end

    enums =
      db_enums
      |> Enum.find(&(&1.name === type))
      |> case do
        nil -> enum_mappings(schema, name)
        v -> v
      end

    %Bootstrap.ColumnDefinition{
      table_name: table_name,
      name: identifier,
      type: type,
      ecto_type: Factori.Ecto.to_ecto_type(type),
      reference: reference,
      enum: enums,
      options: %{
        null: null === "YES",
        ignore: generated === "ALWAYS",
        size: size
      }
    }
  end

  defp enum_mappings(schema, column_name) do
    values =
      schema
      |> Ecto.Enum.values(String.to_existing_atom(column_name))
      |> Enum.map(&to_string/1)

    mappings = Ecto.Enum.mappings(schema, String.to_existing_atom(column_name))

    %Bootstrap.EnumDefinition{name: column_name, values: values, mappings: mappings}
  rescue
    ArgumentError -> []
  end

  defp schemas(repo) do
    otp_app = Keyword.get(repo.config, :otp_app)
    {:ok, modules} = :application.get_key(otp_app, :modules)

    modules
    |> Enum.filter(&function_exported?(&1, :__schema__, 1))
    |> Enum.map(&{&1, &1.__schema__(:source)})
  end
end
