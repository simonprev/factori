defmodule Factori.Mapping do
  @moduledoc false
  @callback match(map()) :: any()
  @callback transform(map(), term()) :: term()

  @optional_callbacks transform: 2
end
