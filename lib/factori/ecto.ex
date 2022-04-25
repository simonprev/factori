defmodule Factori.Ecto do
  def to_ecto_type("uuid"), do: Ecto.UUID
  def to_ecto_type(_), do: :noop

  def dump_value(nil, _), do: nil
  def dump_value(value, :noop), do: value

  def dump_value(value, type) do
    case Ecto.Type.dump(type, value) do
      {:ok, value} -> value
      :error -> nil
    end
  end

  def load_value(nil, _), do: nil
  def load_value(value, :noop), do: value

  def load_value(value, type) do
    case Ecto.Type.load(type, value) do
      {:ok, value} -> value
      :error -> nil
    end
  end
end
