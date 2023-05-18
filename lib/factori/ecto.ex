defmodule Factori.Ecto do
  def to_ecto_type("uuid"), do: Ecto.UUID
  def to_ecto_type(_), do: :noop

  def dump_value(nil, _), do: nil

  def dump_value(value, %{enum: enum} = column) when is_map(enum) do
    dumped_value = Enum.find_value(enum.values, &(&1 === to_string(value) && to_string(value)))

    if !dumped_value,
      do:
        raise(Factori.InvalidEnumError,
          action: "dump",
          table_name: column.table_name,
          name: column.name,
          values: enum.values,
          value: value
        )

    dumped_value
  end

  def dump_value(value, %{ecto_type: :noop}), do: value

  def dump_value(value, column) do
    case Ecto.Type.dump(column.ecto_type, value) do
      {:ok, value} -> value
      :error -> nil
    end
  end

  def load_value(nil, _), do: nil

  def load_value(value, %{enum: enum} = column) when is_map(enum) do
    if enum.mappings do
      enum_value =
        Enum.find_value(enum.mappings, fn {key, enum_value} -> enum_value === value && key end)

      if !enum_value,
        do:
          raise(Factori.InvalidEnumError,
            action: "load",
            table_name: column.table_name,
            name: column.name,
            values: enum.values,
            value: value
          )

      enum_value
    else
      value
    end
  end

  def load_value(value, %{ecto_type: :noop}), do: value

  def load_value(value, column) do
    case Ecto.Type.load(column.ecto_type, value) do
      {:ok, value} -> value
      :error -> nil
    end
  end
end
