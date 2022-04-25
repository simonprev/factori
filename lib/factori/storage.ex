defmodule Factori.Storage do
  @schemas_table_name :schemas

  alias :ets, as: ETS

  def init do
    if ETS.whereis(@schemas_table_name) !== :undefined do
      ETS.delete(@schemas_table_name)
    end

    ETS.new(@schemas_table_name, [:named_table])

    :ok
  end

  def insert_schema_columns({schema, columns}) do
    ETS.insert(@schemas_table_name, {schema, columns})
  end

  def get_schema_columns(schema) do
    case ETS.lookup(@schemas_table_name, schema) do
      [{_, columns}] -> columns
      _ -> []
    end
  end
end
