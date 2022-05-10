defmodule Factori.Storage do
  @callback init(String.t()) :: :ok
  @callback insert(any(), any()) :: any()
  @callback get(atom(), String.t()) :: [Factori.Bootstrap.ColumnDefinition.t()]
end
