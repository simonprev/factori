defmodule Factori.Ecto do
  def to_ecto_type("uuid"), do: Ecto.UUID
  def to_ecto_type(type), do: type

  def dump_value(nil, _), do: nil

  def dump_value(value, %{ecto_type: Ecto.UUID}) do
    case Ecto.Type.dump(Ecto.UUID, value) do
      {:ok, value} -> value
      :error -> nil
    end
  end

  def dump_value(value, %{type: "varchar"}), do: to_string(value)

  def dump_value(value, %{type: type}) when is_struct(value) and type in ~w(json jsonb),
    do: Map.from_struct(value)

  def dump_value(value, %{ecto_schema: nil, enum: enum}) when is_struct(enum),
    do: to_string(value)

  def dump_value(value, _), do: value

  def load_value(nil, _), do: nil

  def load_value(value, %{ecto_type: Ecto.UUID}) do
    case Ecto.Type.load(Ecto.UUID, value) do
      {:ok, value} -> value
      :error -> nil
    end
  end

  def load_value(value, _), do: value
end
