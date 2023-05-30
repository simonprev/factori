defmodule Factori.Mapping.Enum do
  @behaviour Factori.Mapping

  def match(%{enum: enum}) do
    case Enum.take_random(List.wrap(enum.mappings), 1) do
      [] -> Enum.random(enum.values)
      [{key, _value}] -> key
    end
  end
end
