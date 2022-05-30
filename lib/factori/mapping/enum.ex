defmodule Factori.Mapping.Enum do
  @behaviour Factori.Mapping

  def match(%{enum: %{values: values}}), do: Enum.random(values)
end
