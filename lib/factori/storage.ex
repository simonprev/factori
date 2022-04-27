defmodule Factori.Storage do
  alias :ets, as: ETS

  def init(name) do
    if ETS.whereis(name) !== :undefined do
      ETS.delete(name)
    end

    ETS.new(name, [:named_table])

    :ok
  end

  def insert_schema_columns({schema, columns}, name) do
    ETS.insert(name, {schema, columns})
  end

  def get_schema_columns(schema, name) do
    case ETS.lookup(name, schema) do
      [{_, columns}] -> columns
      _ -> []
    end
  end
end
