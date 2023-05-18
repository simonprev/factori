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

    test "simple override" do
      Factori.TestRepo.query!("CREATE TYPE user_type AS ENUM ('admin', 'user')")
      create_table!(:users, [{:add, :type, :user_type, [null: false]}])

      defmodule DbEnumUserOverrideFactory do
        use Factori,
          repo: Factori.TestRepo,
          mappings: [Factori.Mapping.Enum]
      end

      DbEnumUserOverrideFactory.bootstrap()

      user = DbEnumUserOverrideFactory.insert("users", type: "admin")
      assert user.type === "admin"
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
      assert user.type in [:admin, :user]
    end

    test "from schema ecto enum on variant invalid dump" do
      Code.ensure_compiled!(UserEnumSchema)
      create_table!(:users, [{:add, :type, :string, [null: false]}])

      defmodule EctoEnumUserVariantDumpFactory do
        use Factori,
          repo: Factori.TestRepo,
          mappings: [Factori.Mapping.Enum],
          variants: [{:admin, UserEnumSchema, type: :foo}]
      end

      EctoEnumUserVariantDumpFactory.bootstrap()

      assert_raise Factori.InvalidEnumError, ~r/Can't dump value for users.type/, fn ->
        EctoEnumUserVariantDumpFactory.insert(:admin)
      end
    end

    test "from schema ecto enum on variant override" do
      Code.ensure_compiled!(UserEnumSchema)
      create_table!(:users, [{:add, :type, :string, [null: false]}])

      defmodule EctoEnumUserVariantFactory do
        use Factori,
          repo: Factori.TestRepo,
          mappings: [Factori.Mapping.Enum],
          variants: [{:admin, UserEnumSchema, type: :admin}]
      end

      EctoEnumUserVariantFactory.bootstrap()

      user = EctoEnumUserVariantFactory.insert(:admin)
      assert user.type === :admin
    end
  end
end
