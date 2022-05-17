defmodule Factori.Attributes do
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

  defp fetch_reference_value(config, insert_func, columns, attrs, column, source_column) do
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
        if column.options.null do
          nil
        else
          raise CyclicNonNullableReferenceError,
            source_column: source_column,
            column: column
        end

      true ->
        record = insert_func.(config, reference_table_name, [], column)
        Map.get(record, reference_column_name)
    end
  end

  def map(config, insert_func, table_name, attrs, source_column) do
    columns =
      table_name
      |> config.storage.get(config.storage_name)
      |> Enum.sort_by(&((&1.reference && 1) || 0))

    {db_attrs, struct_attrs} =
      Enum.split_with(attrs, fn {attr, _} ->
        Enum.find(columns, &(&1.name === attr))
      end)

    db_attrs =
      Enum.reduce(columns, db_attrs, fn column, attrs ->
        value =
          if column.reference do
            fetch_reference_value(config, insert_func, columns, attrs, column, source_column)
          else
            Keyword.get_lazy(attrs, column.name, fn ->
              value_mapping =
                Enum.find_value(config.mappings, fn mapping ->
                  value = find_mapping_value(mapping, column, config.options)
                  value !== :not_found && {:ok, value}
                end)

              case value_mapping do
                {:ok, value} ->
                  Enum.reduce(config.mappings, value, fn mapping, acc ->
                    find_transformed_value(mapping, column, acc)
                  end)

                _ ->
                  Logger.warn("Can't find a mapping for #{inspect(column)}")

                  nil
              end
            end)
          end

        value = Factori.Ecto.dump_value(value, column.ecto_type)
        [{column.name, value} | attrs]
      end)

    {db_attrs, struct_attrs}
  end

  defp find_transformed_value(_mapping, _column, nil), do: nil

  defp find_transformed_value(mapping, column, value) when is_list(mapping) do
    if mapping[:transform],
      do: mapping[:transform].(column, value),
      else: value
  end

  defp find_transformed_value(mapping, _column, value) when is_function(mapping) do
    value
  end

  defp find_transformed_value(mapping, column, value) when is_atom(mapping) do
    if function_exported?(mapping, :transform, 2),
      do: mapping.transform(column, value),
      else: value
  end

  defp find_mapping_value(mapping, column, options) when is_list(mapping) do
    maybe_nil(column, options, fn -> mapping[:match].(column) end)
  rescue
    FunctionClauseError -> :not_found
  end

  defp find_mapping_value(mapping, column, options) when is_function(mapping) do
    maybe_nil(column, options, fn -> mapping.(column) end)
  rescue
    FunctionClauseError -> :not_found
  end

  defp find_mapping_value(module, column, options) when is_atom(module) do
    maybe_nil(column, options, fn -> module.match(column) end)
  rescue
    FunctionClauseError -> :not_found
  end

  defp maybe_nil(column, options, func) do
    if column.options.null && nil_probability?(options), do: nil, else: func.()
  end

  defp nil_probability?(options), do: :rand.uniform() > options.nil_probability
end
