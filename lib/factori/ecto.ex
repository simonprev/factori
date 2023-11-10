defmodule Factori.Ecto do
  def to_ecto_type("uuid"), do: Ecto.UUID
  def to_ecto_type(type), do: type

  def dump_value(nil, _), do: nil

  def dump_value(value, column) when is_struct(value) and not is_nil(column.struct_embed) do
    {_, _, key_columns} = column.struct_embed

    value
    |> Map.from_struct()
    |> Enum.map(fn {struct_key, struct_value} ->
      key_column = Enum.find(key_columns, &(&1.name === struct_key))

      key_column =
        if key_column && key_column.ecto_type === Ecto.UUID,
          do: %{key_column | ecto_type: nil},
          else: key_column

      {struct_key, dump_value(struct_value, key_column)}
    end)
    |> Map.new()
  end

  def dump_value(value, column) when is_struct(value) and column.type in ~w(json jsonb) do
    Map.from_struct(value)
  end

  def dump_value(value, column) when is_list(value),
    do: Enum.map(value, &dump_value(&1, column))

  def dump_value(value, %{ecto_schema: nil, enum: enum}) when is_struct(enum),
    do: to_string(value)

  def dump_value(value, %{enum: %{name: enum_name}, type: column_type})
      when enum_name === column_type,
      do: to_string(value)

  def dump_value(value, column) when column.type === "varchar", do: to_string(value)
  def dump_value(value, column) when column.type === "_varchar", do: to_string(value)

  def dump_value(value, %{ecto_type: ecto_type_module})
      when is_atom(ecto_type_module) do
    with true <- function_exported?(ecto_type_module, :dump, 1),
         {:ok, value} <- Ecto.Type.dump(ecto_type_module, value) do
      value
    else
      _ -> value
    end
  end

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
