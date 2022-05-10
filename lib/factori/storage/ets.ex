defmodule Factori.Storage.ETS do
  @behaviour Factori.Storage

  alias :ets, as: ETS

  def init(name) do
    if ETS.whereis(name) !== :undefined, do: ETS.delete(name)
    ETS.new(name, [:named_table])

    :ok
  end

  def insert({schema, columns}, name) do
    ETS.insert(name, {schema, columns})
  end

  def get(schema, name) do
    case ETS.lookup(name, schema) do
      [{_, columns}] -> columns
      _ -> []
    end
  rescue
    ArgumentError -> []
  end
end
