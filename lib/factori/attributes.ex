defmodule Factori.Attributes do
  require Logger

  defmodule CyclicNonNullableReferenceError do
    defexception [:source_column, :column]

    @impl true
    def message(%{source_column: source, column: column}) do
      """
      Cyclic dependencies are not supported.

      "#{source.table_name}"."#{source.name}" is not nullable and references "#{column.table_name}"."#{column.name}" who is also not nullable.
      To fix this, make one of them nullable.
      """
    end
  end

  @spec map(
          Factori.Config.t(),
          String.t(),
          Keyword.t(),
          Factori.Bootstrap.ColumnDefinition.t(),
          boolean()
        ) :: {Keyword.t(), Keyword.t()}
  def map(config, table_name, attrs, source_column, ecto_dump_value?) do
    columns =
      table_name
      |> config.storage.get(config.storage_name)
      |> Enum.reject(& &1.options.ignore)
      |> Enum.sort_by(&((&1.reference && 1) || 0))

    {db_attrs, struct_attrs} =
      Enum.split_with(attrs, fn {attr, _} ->
        Enum.find(columns, &(&1.name === attr))
      end)

    db_attrs =
      Enum.reduce(columns, db_attrs, fn column, attrs ->
        new_value = reference_or_mapped_value(config, columns, attrs, column, source_column)

        value = Keyword.get_lazy(attrs, column.name, new_value)
        value = Enum.reduce(config.mappings, value, &find_transformed_value(&1, column, &2))
        value = if ecto_dump_value?, do: Factori.Ecto.dump_value(value, column), else: value
        Keyword.put(attrs, column.name, value)
      end)

    {Enum.uniq(db_attrs), Enum.uniq(struct_attrs)}
  end

  defp reference_or_mapped_value(config, columns, attrs, column, source_column) do
    if column.reference do
      fn -> fetch_reference(config, columns, attrs, column, source_column) end
    else
      fn ->
        value_mapping =
          Enum.find_value(config.mappings, fn mapping ->
            value = find_mapping_value(config, mapping, column)
            value !== :not_found && {:ok, value}
          end)

        case value_mapping do
          {:ok, value} ->
            Enum.reduce(config.mappings, value, fn mapping, acc ->
              find_transformed_value(mapping, column, acc)
            end)

          _ ->
            Logger.warning("Can't find a mapping for #{inspect(column)}")

            nil
        end
      end
    end
  end

  defp fetch_reference(config, columns, attrs, column, source_column) do
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

      source_column && source_column.options.null === false &&
          source_column.table_name === reference_table_name ->
        if column.options.null do
          nil
        else
          raise CyclicNonNullableReferenceError,
            source_column: source_column,
            column: column
        end

      true ->
        reference = Factori.insert(config, reference_table_name, [], column, nil)
        Map.get(reference, reference_column_name)
    end
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

  defp find_attributes_mapping(config, columns) do
    for column <- columns, into: %{} do
      new_value = reference_or_mapped_value(config, columns, [], column, nil)
      {column.name, new_value.()}
    end
  end

  defp maybe_nested_mapping(config, value) do
    case value do
      {:map, embed_schema, columns} ->
        attributes = find_attributes_mapping(config, columns)
        Map.put(attributes, :__struct__, embed_schema)

      {:list, embed_schema, columns} ->
        attributes = find_attributes_mapping(config, columns)
        [Map.put(attributes, :__struct__, embed_schema)]

      value ->
        value
    end
  end

  defp find_mapping_value(config, mapping, column) when is_list(mapping) do
    maybe_nil(column, config.options, fn ->
      maybe_nested_mapping(config, mapping[:match].(column))
    end)
  rescue
    FunctionClauseError -> :not_found
  end

  defp find_mapping_value(config, mapping, column) when is_function(mapping) do
    maybe_nil(column, config.options, fn -> maybe_nested_mapping(config, mapping.(column)) end)
  rescue
    FunctionClauseError -> :not_found
  end

  defp find_mapping_value(config, module, column) when is_atom(module) do
    maybe_nil(column, config.options, fn ->
      maybe_nested_mapping(config, module.match(column))
    end)
  rescue
    FunctionClauseError -> :not_found
  end

  defp maybe_nil(column, options, func) do
    if column.options.null && nil_probability?(options), do: nil, else: func.()
  end

  defp nil_probability?(options), do: :rand.uniform() < options.nil_probability
end
