defmodule Factori do
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

  defmodule UndefinedTableError do
    defexception [:name]

    @impl true
    def message(%{name: name}) do
      """
      `#{inspect(name)}` is not a known table name.
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
      @storage_name __ENV__.module
      @storage unquote(opts[:storage]) || Factori.Storage.ETS

      def bootstrap do
        adapter = unquote(opts[:adapter]) || Factori.Adapter.Postgresql

        Factori.Bootstrap.init(@storage_name, @storage)
        Factori.Bootstrap.bootstrap(unquote(opts[:repo]), @storage_name, adapter, @storage)
      end

      def insert(table_name, struct_module \\ nil, attrs \\ nil, source_column \\ nil)

      def insert(variant, attrs, source_column, _) when is_atom(variant) do
        unquote(opts[:variants])
        |> List.wrap()
        |> List.keyfind(variant, 0)
        |> do_insert_variant(variant, attrs, source_column)
      end

      def insert(table_name, struct_module, attrs, source_column)
          when is_atom(struct_module) and not is_nil(struct_module) do
        {data, db_attrs, struct_attrs} = do_insert(table_name, attrs, source_column)
        struct = struct(struct_module, data)

        Map.merge(struct, Enum.into(struct_attrs, %{}))
      end

      def insert(table_name, attrs, source_column, _) do
        {data, _db_attrs, struct_attrs} = do_insert(table_name, attrs, source_column)

        Map.merge(data, Enum.into(struct_attrs, %{}))
      end

      defp do_insert_variant({_, table_name}, variant, attrs, source_column)
           when is_binary(table_name) do
        insert(table_name, attrs, source_column)
      end

      defp do_insert_variant({_, table_name, variant_attrs}, variant, attrs, source_column)
           when is_binary(table_name) and is_list(variant_attrs) do
        attrs = Keyword.merge(variant_attrs, attrs || [])
        insert(table_name, attrs, source_column)
      end

      defp do_insert_variant({_, table_name, struct_module}, variant, attrs, source_column)
           when is_binary(table_name) and is_atom(struct_module) do
        insert(table_name, struct_module, attrs, source_column)
      end

      defp do_insert_variant(
             {_, table_name, struct_module, variant_attrs},
             variant,
             attrs,
             source_column
           )
           when is_binary(table_name) and is_atom(struct_module) and is_list(variant_attrs) do
        attrs = Keyword.merge(variant_attrs, attrs || [])
        insert(table_name, struct_module, attrs, source_column)
      end

      defp do_insert_variant({_, struct_module, variant_attrs}, variant, attrs, source_column)
           when is_atom(struct_module) and is_list(variant_attrs) do
        if function_exported?(struct_module, :__schema__, 1) do
          attrs = Keyword.merge(variant_attrs, attrs || [])
          table_name = struct_module.__schema__(:source)
          insert(table_name, struct_module, attrs, source_column)
        else
          raise InvalidSchemaError, schema: struct_module, name: variant
        end
      end

      defp do_insert_variant({_, struct_module}, variant, attrs, source_column)
           when is_atom(struct_module) do
        if function_exported?(struct_module, :__schema__, 1) do
          table_name = struct_module.__schema__(:source)
          insert(table_name, struct_module, attrs, source_column)
        else
          raise InvalidSchemaError, schema: struct_module, name: variant
        end
      end

      defp do_insert_variant(_, variant, _attrs, _source_column) do
        raise UndefinedVariantError,
          name: variant,
          variants: List.wrap(unquote(opts[:variants]))
      end

      defp do_insert(table_name, attrs, source_column) do
        attrs = attrs || []
        ensure_valid_table_name!(table_name)

        {db_attrs, struct_attrs} =
          Factori.Attributes.map(
            __MODULE__,
            List.wrap(unquote(opts[:mappings])),
            table_name,
            attrs,
            {@storage, @storage_name},
            source_column
          )

        data = hd(insert_all(table_name, [db_attrs]))
        {data, db_attrs, struct_attrs}
      end

      def match(_), do: :not_found
      defoverridable match: 1

      defp ensure_valid_table_name!(table_name) do
        case @storage.get(table_name, @storage_name) do
          [] -> raise UndefinedTableError, name: table_name
          _ -> :ok
        end
      end

      defp insert_all(table_name, attrs) do
        [first_attrs | _] = attrs

        attrs
        |> Enum.chunk_every(1000)
        |> Enum.flat_map(fn attrs ->
          case unquote(opts[:repo]).insert_all(table_name, attrs,
                 returning: Keyword.keys(first_attrs)
               ) do
            {_, records} ->
              columns = @storage.get(table_name, @storage_name)
              Enum.map(records, &load_record_values(&1, columns))

            _ ->
              []
          end
        end)
      end

      defp load_record_values(record, columns) do
        Enum.reduce(columns, record, fn column, record ->
          Map.update(record, column.name, nil, &Factori.Ecto.load_value(&1, column.ecto_type))
        end)
      end
    end
  end
end
