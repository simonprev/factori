defmodule UserEnumSchema do
  use Ecto.Schema

  schema "users" do
    field(:type_enum, Ecto.Enum, values: [:admin, :user])
  end
end
