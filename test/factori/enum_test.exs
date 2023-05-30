defmodule Factori.EnumTest do
  use Factori.EctoCase, async: true

  describe "enum" do
    test "simple" do
      Factori.TestRepo.query!("CREATE TYPE simple_user_type AS ENUM ('admin', 'user')")
      create_table!(:simple_users, [{:add, :type, :simple_user_type, [null: false]}])

      defmodule DbEnumUserFactory do
        use Factori,
          repo: Factori.TestRepo,
          mappings: [Factori.Mapping.Enum]
      end

      DbEnumUserFactory.bootstrap()

      user = DbEnumUserFactory.insert("simple_users")
      assert user.type in ["admin", "user"]
    end

    test "simple override" do
      Factori.TestRepo.query!("CREATE TYPE simple_override_user_type AS ENUM ('admin', 'user')")

      create_table!(:simple_override_users, [
        {:add, :type, :simple_override_user_type, [null: false]}
      ])

      defmodule DbEnumUserOverrideFactory do
        use Factori,
          repo: Factori.TestRepo,
          mappings: [Factori.Mapping.Enum]
      end

      DbEnumUserOverrideFactory.bootstrap()

      user = DbEnumUserOverrideFactory.insert("simple_override_users", type: "admin")
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

    test "from schema ecto variant enum" do
      Code.ensure_compiled!(UserEnumSchema)
      create_table!(:users, [{:add, :type, :string, [null: false]}])

      defmodule EctoEnumVariantUserFactory do
        use Factori,
          repo: Factori.TestRepo,
          mappings: [Factori.Mapping.Enum],
          variants: [{:user, UserEnumSchema}]
      end

      EctoEnumVariantUserFactory.bootstrap()

      user = EctoEnumVariantUserFactory.insert(:user)
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

      assert_raise Ecto.ChangeError,
                   ~r/value `:foo` for `UserEnumSchema.type` in `insert_all` does not match type/,
                   fn ->
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
