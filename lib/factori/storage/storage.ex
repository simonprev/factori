defmodule Factori.Storage do
  @moduledoc false
  @callback init(atom()) :: :ok
  @callback insert(any(), any()) :: any()
  @callback get(atom(), String.t()) :: [Factori.Bootstrap.ColumnDefinition.t()]
end
