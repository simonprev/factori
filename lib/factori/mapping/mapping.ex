defmodule Factori.Mapping do
  @callback match(map()) :: any()
  @callback transform(map(), term()) :: term()

  @optional_callbacks transform: 2
end
