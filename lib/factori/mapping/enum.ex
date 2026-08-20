defmodule Factori.Mapping.Enum do
  @moduledoc false
  @behaviour Factori.Mapping

  def match(%{enum: enum}) when not is_nil(enum) do
    elem(Enum.random(enum.mappings), 0)
  end
end
