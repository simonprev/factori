defmodule Factori.Bootstrap do
  defmodule ReferenceDefinition do
    defstruct target: nil,
              target_column: nil,
              source: nil,
              source_column: nil

    @type t :: %__MODULE__{}
  end

  defmodule ColumnDefinition do
    defstruct table_name: nil,
              name: nil,
              type: nil,
              options: %{},
              ecto_type: nil,
              reference: nil

    @type t :: %__MODULE__{}
  end

  def init(config = %Factori.Config{}), do: config.storage.init(config.storage_name)

  def bootstrap(config = %Factori.Config{}) do
    config.repo
    |> config.adapter.columns!()
    |> Enum.each(&config.storage.insert(&1, config.storage_name))
  end

  def query!(repo, query) do
    result = Ecto.Adapters.SQL.query!(repo, query, [])
    result.rows
  end
end
