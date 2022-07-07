defmodule Factori.EnumTest do
  use Factori.EctoCase, async: true

  describe "enum" do
    test "simple" do
      Factori.TestRepo.query!("CREATE TYPE user_type AS ENUM ('admin', 'user')")
      create_table!(:users, [{:add, :type, :user_type, [null: false]}])

      defmodule UserFactory do
        use Factori,
          repo: Factori.TestRepo,
          mappings: [Factori.Mapping.Enum]
      end

      UserFactory.bootstrap()

      user = UserFactory.insert("users")
      assert user.type in ["admin", "user"]
    end

    test "from schema ecto enum" do
      Code.ensure_compiled!(UserEnumSchema)
      create_table!(:users, [{:add, :type_enum, :string, [null: false]}])

      defmodule UserFactory do
        use Factori,
          repo: Factori.TestRepo,
          mappings: [Factori.Mapping.Enum]
      end

      UserFactory.bootstrap()

      user = UserFactory.insert("users")
      assert user.type_enum in ["admin", "user"]
    end
  end
end
