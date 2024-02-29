defmodule UserAddressEmbedSchema do
  @moduledoc false
  # Support for Factori.EctoEmbedsTest. Stored in a seperate file to ensure schema
  # module is registered in :application.get_key(otp_app, :modules)
  use Ecto.Schema

  schema "users_address_embed" do
    field(:street, :string)
  end
end

defmodule UserEmbedSchema do
  @moduledoc false
  # Support for Factori.EctoEmbedsTest. Stored in a seperate file to ensure schema
  # module is registered in :application.get_key(otp_app, :modules)
  use Ecto.Schema

  @primary_key false
  schema "users_embed" do
    embeds_many :associates, Associate do
      field(:name, :string)

      embeds_one :other_lead, OtherLead do
        field(:inserted_at, :utc_datetime)
      end
    end

    embeds_one :lead, Lead do
      field(:email, :string)
      field(:binary_id, :binary_id)
      field(:boolean, :boolean)
      field(:integer, :integer)
      field(:binary, :binary)
      field(:array, {:array, :string})
      field(:map, :map)
      field(:map_string, {:map, :string})
      field(:decimal, :decimal)
      field(:date, :date)
      field(:time, :time)
      field(:time_usec, :time)
      field(:float, :float)
      field(:utc_datetime, :utc_datetime)
      field(:utc_datetime_usec, :utc_datetime_usec)
      field(:naive_datetime, :naive_datetime)
      field(:naive_datetime_usec, :naive_datetime_usec)
      field(:uuid, Ecto.UUID)
      field(:enum, Ecto.Enum, values: ~w(a b c d e f)a)
      belongs_to(:address, UserAddressEmbedSchema)
    end
  end
end
