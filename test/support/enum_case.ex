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

defmodule PostEnumSchema do
  @moduledoc false
  use Ecto.Schema

  schema "posts_enum" do
    field(:status, Ecto.Enum, values: [draft: "Draft", admin: "Admin"])
  end
end

defmodule UserPostEnumSchema do
  @moduledoc false
  use Ecto.Schema

  @primary_key false
  schema "users_posts_enum" do
    belongs_to(:post, PostEnumSchema)
  end
end
