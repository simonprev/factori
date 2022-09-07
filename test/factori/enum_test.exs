defmodule Factori.EnumTest do
  use Factori.EctoCase, async: true

  describe "enum" do
    test "simple" do
      Factori.TestRepo.query!("CREATE TYPE user_type AS ENUM ('admin', 'user')")
      create_table!(:users, [{:add, :type, :user_type, [null: false]}])

      defmodule DbEnumUserFactory do
        use Factori,
          repo: Factori.TestRepo,
          mappings: [Factori.Mapping.Enum]
      end

      DbEnumUserFactory.bootstrap()

      user = DbEnumUserFactory.insert("users")
      assert user.type in ["admin", "user"]
    end

    test "from schema ecto enum" do
      Code.ensure_compiled!(UserEnumSchema)
      create_table!(:users, [{:add, :type, :string, [null: false]}])

      defmodule EctoEnumUserFactory do
        use Factori,
          repo: Factori.TestRepo,
          mappings: [Factori.Mapping.Enum]
      end

      EctoEnumUserFactory.bootstrap()

      user = EctoEnumUserFactory.insert("users")
      assert user.type in ["admin", "user"]
    end
  end
end
