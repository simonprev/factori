defmodule Factori do
  alias Factori.Bootstrap
  alias Factori.Ecto, as: FactoryEcto
  alias Factori.Storage
  alias Factori.Attributes

  defmodule UndefinedVariantError do
    defexception [:name, :variants]

    @impl true
    def message(%{name: name, variants: variants}) do
      """
      `#{inspect(name)}` is not a valid variant name.

      Valid variants are:
      #{Enum.map_join(variants, "\n", fn variant -> inspect(elem(variant, 0)) end)}
      """
    end
  end

  defmodule InvalidSchemaError do
    defexception [:schema, :name]

    @impl true
    def message(%{schema: schema, name: name}) do
      """

      #{inspect(schema)} is not a valid Ecto schema for #{inspect(name)} variant.
      It does not expose a `def __schema__(:source)` function that returns the table name.
      """
    end
  end

  defmacro __using__(opts) do
    quote do
      @repo unquote(opts[:repo])
      @mappings List.wrap(unquote(opts[:mappings]))
      @variants List.wrap(unquote(opts[:variants]))

      def bootstrap do
        Bootstrap.init()
        Bootstrap.bootstrap(@repo)
      end

      def insert_list(count, table_name, attrs \\ []) do
        ensure_valid_table_name!(table_name)

        attrs = for _ <- 1..count, do: Attributes.map(__MODULE__, @mappings, table_name, attrs)

        insert_all(table_name, attrs)
      end

      def insert(table_name, struct_module \\ nil, attrs \\ nil, source_column \\ nil)

      def insert(variant, attrs, source_column, _) when is_atom(variant) do
        case List.keyfind(@variants, variant, 0) do
          {_, table_name} when is_binary(table_name) ->
            insert(table_name, attrs, source_column)

          {_, table_name, variant_attrs} when is_binary(table_name) and is_list(variant_attrs) ->
            attrs = Keyword.merge(attrs || [], variant_attrs)
            insert(table_name, attrs, source_column)

          {_, table_name, struct_module} when is_binary(table_name) and is_atom(struct_module) ->
            insert(table_name, struct_module, attrs, source_column)

          {_, table_name, struct_module, variant_attrs} when is_binary(table_name) and is_atom(struct_module) and is_list(variant_attrs) ->
            attrs = Keyword.merge(attrs || [], variant_attrs)
            insert(table_name, struct_module, attrs, source_column)

          {_, struct_module, variant_attrs} when is_atom(struct_module) and is_list(variant_attrs) ->
            if function_exported?(struct_module, :__schema__, 1) do
              attrs = Keyword.merge(attrs || [], variant_attrs)
              table_name = struct_module.__schema__(:source)
              insert(table_name, struct_module, attrs, source_column)
            else
              raise InvalidSchemaError, schema: struct_module, name: variant
            end

          {_, struct_module} when is_atom(struct_module) ->
            if function_exported?(struct_module, :__schema__, 1) do
              table_name = struct_module.__schema__(:source)
              insert(table_name, struct_module, attrs, source_column)
            else
              raise InvalidSchemaError, schema: struct_module, name: variant
            end

          _ ->
            raise UndefinedVariantError, name: variant, variants: @variants
        end
      end

      def insert(table_name, struct_module, attrs, source_column)
          when is_atom(struct_module) and not is_nil(struct_module) do
        data = insert(table_name, attrs, source_column)
        struct(struct_module, data)
      end

      def insert(table_name, attrs, source_column, _) do
        attrs = attrs || []
        ensure_valid_table_name!(table_name)

        attrs = Attributes.map(__MODULE__, @mappings, table_name, attrs, source_column)

        hd(insert_all(table_name, [attrs]))
      end

      def match(_), do: :not_found
      defoverridable match: 1

      defp ensure_valid_table_name!(table_name) do
        case Storage.get_schema_columns(table_name) do
          [] -> raise("#{inspect(table_name)} table does not exists in your database.")
          _ -> :ok
        end
      end

      defp insert_all(table_name, attrs) do
        [first_attrs | _] = attrs

        attrs
        |> Enum.chunk_every(1000)
        |> Enum.flat_map(fn attrs ->
          case @repo.insert_all(table_name, attrs, returning: Keyword.keys(first_attrs)) do
            {_, records} ->
              columns = Storage.get_schema_columns(table_name)
              Enum.map(records, &load_record_values(&1, columns))

            _ ->
              []
          end
        end)
      end

      defp load_record_values(record, columns) do
        Enum.reduce(columns, record, fn column, record ->
          Map.update(record, column.name, nil, &FactoryEcto.load_value(&1, column.ecto_type))
        end)
      end
    end
  end
end
