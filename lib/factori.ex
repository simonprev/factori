defmodule Factori do
  alias Factori.Attributes
  alias Factori.Variant

  defmodule UndefinedVariantError do
    defexception [:name, :variants]

    @impl true
    def message(%{name: name, variants: []}) do
      """
      `#{inspect(name)}` is not a valid variant name. No variants were defined in your Factory module.
      """
    end

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

  defmodule Options do
    defstruct nil_probability: 0.5
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

  defmodule Config do
    defstruct storage_name: nil,
              storage: nil,
              repo: nil,
              adapter: nil,
              variants: [],
              mappings: [],
              options: []

    @type t :: %__MODULE__{}
  end

  @spec bootstrap(Factori.Config.t()) :: no_return()
  def bootstrap(factory_config) do
    Factori.Bootstrap.init(factory_config)
    Factori.Bootstrap.bootstrap(factory_config)
  end

  def insert_list(
        config,
        table_name,
        count,
        struct_module \\ nil,
        attrs \\ nil,
        source_column \\ nil
      )

  def insert_list(config, variant, count, attrs, source_column, _) when is_atom(variant) do
    found_variant = find_variant(config.variants, variant)
    Variant.insert_list(config, found_variant, variant, count, attrs, source_column)
  end

  def insert_list(config, table_name, count, struct_module, attrs, source_column)
      when is_atom(struct_module) and not is_nil(struct_module) do
    data = insert_list(config, table_name, count, attrs, source_column, struct_module)

    Enum.map(data, &struct(struct_module, &1))
  end

  def insert_list(config, table_name, count, attrs, source_column, _) do
    ensure_valid_table_name!(config, table_name)

    data =
      for _ <- 1..count,
          into: [],
          do: map_attributes(config, table_name, attrs, source_column)

    db_attrs = Enum.map(data, &elem(&1, 0))

    config
    |> insert_all(table_name, db_attrs)
    |> Enum.zip(data)
    |> Enum.map(fn {row, {_, struct_attrs}} ->
      Map.merge(row, Enum.into(struct_attrs, %{}))
    end)
  end

  def insert(config, table_name, struct_module \\ nil, attrs \\ nil, source_column \\ nil)

  def insert(config, variant, attrs, source_column, _) when is_atom(variant) do
    found_variant = find_variant(config.variants, variant)
    Variant.insert(config, found_variant, variant, attrs, source_column)
  end

  def insert(config, table_name, struct_module, attrs, source_column)
      when is_atom(struct_module) and not is_nil(struct_module) do
    struct(
      struct_module,
      insert(config, table_name, attrs, source_column, struct_module)
    )
  end

  def insert(config, table_name, attrs, source_column, _) do
    ensure_valid_table_name!(config, table_name)

    {db_attrs, struct_attrs} = map_attributes(config, table_name, attrs, source_column)
    data = hd(insert_all(config, table_name, [db_attrs]))

    Map.merge(data, Enum.into(struct_attrs, %{}))
  end

  def build(config, table_name, struct_module \\ nil, attrs \\ nil, source_column \\ nil)

  def build(config, variant, attrs, source_column, _) when is_atom(variant) do
    found_variant = find_variant(config.variants, variant)
    Variant.build(config, found_variant, variant, attrs, source_column)
  end

  def build(config, table_name, struct_module, attrs, source_column)
      when is_atom(struct_module) and not is_nil(struct_module) do
    struct(
      struct_module,
      build(config, table_name, attrs, source_column, struct_module)
    )
  end

  def build(config, table_name, attrs, source_column, _) do
    ensure_valid_table_name!(config, table_name)

    {db_attrs, struct_attrs} = map_attributes(config, table_name, attrs, source_column)
    Map.merge(Enum.into(db_attrs, %{}), Enum.into(struct_attrs, %{}))
  end

  def seed(config, variant, count, attrs, source_column, _) when is_atom(variant) do
    found_variant = find_variant(config.variants, variant)
    Variant.seed(config, found_variant, variant, count, attrs, source_column)
  end

  def seed(config, table_name, count, struct_module, attrs, source_column)
      when is_atom(struct_module) and not is_nil(struct_module) do
    seed(config, table_name, count, attrs, source_column, struct_module)
  end

  def seed(config, table_name, count, attrs, source_column, _) do
    ensure_valid_table_name!(config, table_name)
    parent = self()

    data =
      for _ <- 1..count,
          into: [],
          do: map_attributes(config, table_name, attrs, source_column)

    data
    |> Enum.map(&elem(&1, 0))
    |> Stream.chunk_every(1000)
    |> Task.async_stream(
      &config.repo.insert_all(table_name, &1, caller: parent, returning: false),
      ordered: false
    )
    |> Stream.run()

    :ok
  end

  defp ensure_valid_table_name!(config, table_name) do
    if Enum.empty?(config.storage.get(table_name, config.storage_name)) do
      raise UndefinedTableError, name: table_name
    end
  end

  defp map_attributes(config, table_name, attrs, source_column) do
    Attributes.map(
      config,
      &insert/5,
      table_name,
      List.wrap(attrs),
      source_column
    )
  end

  defp insert_all(config, table_name, attrs) do
    columns = config.storage.get(table_name, config.storage_name)
    returning = Enum.map(columns, & &1.name)

    attrs
    |> Enum.chunk_every(1000)
    |> Enum.flat_map(fn attrs ->
      case config.repo.insert_all(table_name, attrs, returning: returning) do
        {_, records} ->
          Enum.map(records, &load_record_values(&1, columns))

        _ ->
          []
      end
    end)
  end

  defp find_variant(variants, variant) do
    List.keyfind(variants, variant, 0)
  end

  defp load_record_values(record, columns) do
    Enum.reduce(columns, record, fn column, record ->
      Map.update(record, column.name, nil, &Factori.Ecto.load_value(&1, column.ecto_type))
    end)
  end

  defmacro __using__(opts) do
    quote location: :keep do
      def bootstrap, do: Factori.bootstrap(config())

      defp config do
        %Factori.Config{
          storage_name: __MODULE__,
          storage: unquote(opts[:storage]) || Factori.Storage.ETS,
          repo: unquote(opts[:repo]),
          adapter: unquote(opts[:adapter]) || Factori.Adapter.Postgresql,
          mappings: List.wrap(unquote(opts[:mappings])),
          variants: List.wrap(unquote(opts[:variants])),
          options: struct!(Factori.Options, List.wrap(unquote(opts[:options])))
        }
      end

      def insert(table_name, struct_module \\ nil, attrs \\ nil, source_column \\ nil) do
        Factori.insert(config(), table_name, struct_module, attrs, source_column)
      end

      def build(table_name, struct_module \\ nil, attrs \\ nil, source_column \\ nil) do
        Factori.build(config(), table_name, struct_module, attrs, source_column)
      end

      def params_for(table_name, struct_module \\ nil, attrs \\ nil, source_column \\ nil) do
        data = Factori.build(config(), table_name, struct_module, attrs, source_column)
        keys_to_string(data)
      end

      def insert_list(
            table_name,
            count \\ 1,
            struct_module \\ nil,
            attrs \\ nil,
            source_column \\ nil
          )
          when is_integer(count) do
        Factori.insert_list(config(), table_name, count, struct_module, attrs, source_column)
      end

      defp keys_to_string(json) when is_map(json) do
        Map.new(json, &reduce_keys_to_string/1)
      end

      defp reduce_keys_to_string({key, val}) when is_map(val),
        do: {to_string(key), keys_to_string(val)}

      defp reduce_keys_to_string({key, val}) when is_list(val),
        do: {to_string(key), Enum.map(val, &keys_to_string(&1))}

      defp reduce_keys_to_string({key, val}), do: {to_string(key), val}

      def seed(
            table_name,
            count \\ 1,
            struct_module \\ nil,
            attrs \\ nil,
            source_column \\ nil
          )
          when is_integer(count) do
        Factori.seed(config(), table_name, count, struct_module, attrs, source_column)
      end

      def match(_), do: :not_found
      defoverridable match: 1
    end
  end
end
