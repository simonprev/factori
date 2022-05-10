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

  def init(name, storage), do: storage.init(name)

  def bootstrap(repo, name, adapter, storage) do
    repo
    |> adapter.columns!()
    |> Enum.each(&storage.insert(&1, name))
  end

  def query!(repo, query) do
    result = Ecto.Adapters.SQL.query!(repo, query, [])
    result.rows
  end
end
