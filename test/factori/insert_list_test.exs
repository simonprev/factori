defmodule Factori.InsertListTest do
  use Factori.EctoCase, async: true

  describe "insert_list" do
    test "unknown" do
      defmodule UnknownFactory do
        use Factori, repo: Factori.TestRepo
      end

      assert_raise Factori.UndefinedVariantError, ~r/foo/, fn ->
        UnknownFactory.insert_list(:foo)
      end
    end

    test "invalid schema" do
      defmodule InvalidModule do
      end

      defmodule InvalidFactory do
        use Factori, repo: Factori.TestRepo, variants: [{:invalid_variant_name, InvalidModule}]
      end

      assert_raise Factori.InvalidSchemaError, ~r/invalid_variant_name/, fn ->
        InvalidFactory.insert_list(:invalid_variant_name)
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

      [named] = TableUserFactory.insert_list("users")
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

      [named] = UserFactory.insert_list(:user)
      assert named.id === "1"
    end

    test "count" do
      create_table!(:users, [{:add, :id, :string, [size: 1, null: false]}])

      defmodule CountUserFactory do
        use Factori,
          repo: Factori.TestRepo,
          variants: [{:user, "users"}],
          mappings: [
            [match: fn %{name: :id} -> "1" end]
          ]
      end

      CountUserFactory.bootstrap()

      users = CountUserFactory.insert_list(:user, 10)
      assert length(users) === 10
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

      [named] = UserOverrideFactory.insert_list(:user)
      assert named.id === "3"
    end
  end
end
