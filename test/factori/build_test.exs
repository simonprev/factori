defmodule Factori.BuildTest do
  use Factori.EctoCase, async: true

  describe "params_for" do
    test "keys as string" do
      create_table!(:users, [{:add, :id, :string, [size: 1, null: false]}])

      defmodule ParamsUserFactory do
        use Factori,
          repo: Factori.TestRepo,
          mappings: [
            fn %{name: :id} -> "1" end
          ]
      end

      ParamsUserFactory.bootstrap()

      named = ParamsUserFactory.params_for("users")
      assert named["id"] === "1"
    end
  end

  describe "build" do
    test "unknown" do
      defmodule UnknownFactory do
        use Factori, repo: Factori.TestRepo
      end

      assert_raise Factori.UndefinedVariantError, ~r/foo/, fn ->
        UnknownFactory.build(:foo)
      end
    end

    test "invalid schema" do
      defmodule InvalidModule do
      end

      defmodule InvalidFactory do
        use Factori, repo: Factori.TestRepo, variants: [{:invalid_variant_name, InvalidModule}]
      end

      assert_raise Factori.InvalidSchemaError, ~r/invalid_variant_name/, fn ->
        InvalidFactory.build(:invalid_variant_name)
      end
    end

    test "table" do
      create_table!(:users, [{:add, :id, :string, [size: 1, null: false]}])

      defmodule TableUserFactory do
        use Factori,
          repo: Factori.TestRepo,
          mappings: [
            fn %{name: :id} -> "1" end
          ]
      end

      TableUserFactory.bootstrap()

      named = TableUserFactory.build("users")
      assert named.id === "1"
    end

    test "name" do
      create_table!(:users, [{:add, :id, :string, [size: 1, null: false]}])

      defmodule UserFactory do
        use Factori,
          repo: Factori.TestRepo,
          variants: [{:user, "users"}],
          mappings: [
            [match: fn %{name: :id} -> "1" end]
          ]
      end

      UserFactory.bootstrap()

      named = UserFactory.build(:user)
      assert named.id === "1"
    end

    test "name with override" do
      create_table!(:users, [{:add, :id, :string, [size: 1, null: false]}])

      defmodule UserOverrideFactory do
        use Factori,
          repo: Factori.TestRepo,
          variants: [{:user, "users", id: "3"}],
          mappings: [
            [match: fn %{name: :id} -> "1" end]
          ]
      end

      UserOverrideFactory.bootstrap()

      named = UserOverrideFactory.build(:user)
      assert named.id === "3"
    end

    test "do not persist" do
      create_table!(:users, [{:add, :id, :string, [size: 1, null: false]}])

      defmodule DoNotPersistFactory do
        use Factori,
          repo: Factori.TestRepo,
          mappings: [
            fn _ -> "1" end
          ]
      end

      DoNotPersistFactory.bootstrap()

      DoNotPersistFactory.build("users")
      results = Factori.TestRepo.query!("select id from users").rows
      assert results === []
    end
  end
end
