defmodule Factori.Bootstrap do
  defmodule EnumDefinition do
    defstruct name: nil, mappings: []

    @type t :: %__MODULE__{
            name: String.t(),
            mappings: list()
          }
  end

  defmodule EmbedDefinition do
    defstruct name: nil, ecto_schema: nil, cardinality: nil

    @type t :: %__MODULE__{
            name: atom(),
            ecto_schema: module(),
            cardinality: atom()
          }
  end

  defmodule ReferenceDefinition do
    defstruct target: nil,
              target_column: nil,
              source: nil,
              source_column: nil

    @type t :: %__MODULE__{
            target: String.t(),
            source: String.t(),
            target_column: atom(),
            source_column: atom()
          }
  end

  defmodule ColumnDefinition do
    defstruct table_name: nil,
              name: nil,
              type: nil,
              options: %{},
              ecto_type: nil,
              ecto_schema: nil,
              struct_embed: nil,
              struct_type: nil,
              reference: nil,
              enum: nil

    @type t :: %__MODULE__{
            name: atom(),
            type: String.t(),
            options: map(),
            ecto_type: atom() | nil,
            ecto_schema: module() | nil,
            struct_embed: {atom(), module(), list()} | nil,
            struct_type: String.t() | nil,
            reference: ReferenceDefinition.t() | nil,
            enum: EnumDefinition.t() | nil
          }
  end

  @spec init(Factori.Config.t()) :: any()
  def init(config), do: config.storage.init(config.storage_name)

  @spec bootstrap(Factori.Config.t()) :: any()
  def bootstrap(config = %Factori.Config{}) do
    columns = config.adapter.columns!(config.repo)
    Enum.each(columns, &config.storage.insert(&1, config.storage_name))
  end
end
