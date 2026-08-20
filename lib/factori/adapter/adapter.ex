defmodule Factori.Adapter do
  @moduledoc false
  @callback columns!(Ecto.Repo.t()) :: [Factori.Bootstrap.ColumnDefinition.t()]
end
