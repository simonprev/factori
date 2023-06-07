defmodule UserDateTimeSchema do
  @moduledoc false
  # Support for Factori.EctoVariantsTest. Stored in a seperate file to ensure schema
  # module is registered in :application.get_key(otp_app, :modules)
  use Ecto.Schema

  @primary_key false
  schema "users_datetime" do
    field(:inserted_at, :utc_datetime)
    field(:usec_inserted_at, :utc_datetime_usec)
  end
end
