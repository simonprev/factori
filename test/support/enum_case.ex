defmodule UserEnumSchema do
  @moduledoc false
  # Support for Factori.EnumTest. Stored in a seperate file to ensure schema
  # module is registered in :application.get_key(otp_app, :modules)
  use Ecto.Schema

  @primary_key false
  schema "users_enum" do
    field(:type, Ecto.Enum, values: [:admin, :user])
  end
end
