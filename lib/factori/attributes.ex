defmodule Factori.Attributes do
  alias Factori.Ecto, as: FactoryEcto
  alias Factori.Storage

  require Logger

  defmodule CyclicNonNullableReferenceError do
    defexception [:source_column, :column]

    @impl true
    def message(%{source_column: source, column: column}) do
      """
      Cyclic dependencies are not supported.

      "#{source.table_name}"."#{source.name}" is not nullable and references "#{column.table_name}"."#{column.name}" who is alos not nullable.
      To fix this, make one of them nullable.
      """
    end
  end

  defp fetch_reference_value(insert, columns, attrs, column, source_column) do
    {reference_table_name, reference_column_name} = column.reference

    existing_reference_value =
      columns
      |> Enum.filter(&(&1.reference === column.reference))
      |> Enum.map(&Keyword.get(attrs, &1.name))
      |> Enum.reject(&is_nil/1)
      |> List.first()

    cond do
      not is_nil(existing_reference_value) ->
        existing_reference_value

      source_column && source_column.table_name === reference_table_name ->
        if column.options[:null] do
          nil
        else
          raise CyclicNonNullableReferenceError,
            source_column: source_column,
            column: column
        end

      true ->
        record = insert.(reference_table_name, [], column)
        Map.get(record, reference_column_name)
    end
  end

  def map(factory, mappings, table_name, attrs, source_column \\ nil) do
    columns =
      table_name
      |> Storage.get_schema_columns()
      |> Enum.sort_by(&((&1.reference && 1) || 0))

    Enum.reduce(columns, attrs, fn column, attrs ->
      value =
        if column.reference do
          fetch_reference_value(&factory.insert/3, columns, attrs, column, source_column)
        else
          Keyword.get_lazy(attrs, column.name, fn ->
            value_mapping =
              Enum.find_value([factory | mappings], fn module ->
                value = find_mapping_value(module, column)
                value !== :not_found && {:ok, value}
              end)

            case value_mapping do
              {:ok, value} ->
                value

              _ ->
                Logger.warn("Can't find a mapping for #{inspect(column)}")

                nil
            end
          end)
        end

      value = FactoryEcto.dump_value(value, column.ecto_type)
      [{column.name, value} | attrs]
    end)
  end

  defp find_mapping_value(module, column) do
    if column.options.null do
      if nil_probability?(), do: module.match(column), else: nil
    else
      module.match(column)
    end
  rescue
    FunctionClauseError -> :not_found
  end

  defp nil_probability? do
    hd(Enum.take_random([true, false], 1))
  end
end
