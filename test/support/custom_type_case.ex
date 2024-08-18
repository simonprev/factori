defmodule UserCustomTypeSchema do
  @moduledoc false
  # Support for Factori.EctoEmbedsTest. Stored in a seperate file to ensure schema
  # module is registered in :application.get_key(otp_app, :modules)
  use Ecto.Schema

  @primary_key {:id, :string, []}
  schema "users" do
    field(:uuid_slug, Ecto.UUID)
    field(:amount, Money.Ecto.Composite.Type)
  end
end

defmodule DeliveryMethodSchema do
  use Ecto.Schema

  @primary_key {:id, :integer, []}
  schema "delivery_methods" do
    field(:price, Money.Ecto.Composite.Type)
  end
end

defmodule ProductSchema do
  use Ecto.Schema

  @primary_key {:id, :integer, []}
  schema "products" do
    field(:price, Money.Ecto.Composite.Type)
    belongs_to(:delivery_method, DeliveryMethodSchema)
  end
end
