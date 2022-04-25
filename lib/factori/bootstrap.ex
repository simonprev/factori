defmodule Factori.Bootstrap do
  alias Factori

  defmodule ReferenceDefinition do
    defstruct target: nil, target_column: nil, source: nil, source_column: nil
  end

  defmodule ColumnDefinition do
    defstruct table_name: nil,
              name: nil,
              type: nil,
              options: %{},
              ecto_type: nil,
              reference: nil
  end

  @query """
  SELECT
    table_name,
    column_name,
    udt_name,
    is_nullable,
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

  def init, do: Factori.Storage.init()

  def bootstrap(repo) do
    repo
    |> fetch_column_definitions!()
    |> persist_column_definitions()
  end

  defp persist_column_definitions(columns) do
    Enum.each(columns, &Factori.Storage.insert_schema_columns/1)
  end

  defp fetch_column_definitions!(repo) do
    references = fetch_reference_definitions!(repo)

    repo
    |> query!(@query)
    |> Enum.group_by(&List.first/1)
    |> Enum.reduce(%{}, fn {table_name, columns}, acc ->
      references = Map.get(references, table_name, [])

      columns =
        columns
        |> Enum.map(&generate_column_definition(references, &1))
        |> Enum.group_by(& &1.name)
        |> Enum.map(fn {name, [definition]} -> {name, definition} end)
        |> Enum.into(%{})
        |> Map.values()

      Map.put(acc, table_name, columns)
    end)
  end

  defp fetch_reference_definitions!(repo) do
    repo
    |> query!(@references)
    |> Enum.map(fn [target, target_column, source, source_column] ->
      %ReferenceDefinition{
        source: source,
        target: target,
        source_column: String.to_atom(source_column),
        target_column: String.to_atom(target_column)
      }
    end)
    |> Enum.group_by(& &1.source)
  end

  defp generate_column_definition(references, [
         table_name,
         name,
         type,
         null,
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

    %ColumnDefinition{
      table_name: table_name,
      name: identifier,
      type: type,
      ecto_type: Factori.Ecto.to_ecto_type(type),
      reference: reference,
      options: %{
        null: null === "YES",
        size: size
      }
    }
  end

  defp query!(repo, query) do
    result = Ecto.Adapters.SQL.query!(repo, query, [])
    result.rows
  end
end
