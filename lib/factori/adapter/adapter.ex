defmodule Factori.Adapter do
  @callback columns!(Ecto.Repo.t()) :: [Factori.Bootstrap.ColumnDefinition.t()]
end
