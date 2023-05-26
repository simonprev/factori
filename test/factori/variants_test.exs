defmodule Factori.VariantsTest do
  use Factori.EctoCase, async: true

  describe "variants" do
    test "unknown" do
      defmodule UnknownFactory do
        use Factori, repo: Factori.TestRepo
      end

      assert_raise Factori.UndefinedVariantError, ~r/foo/, fn ->
        UnknownFactory.insert(:foo)
      end
    end

    test "invalid schema" do
      defmodule InvalidModule do
      end

      defmodule InvalidFactory do
        use Factori, repo: Factori.TestRepo, variants: [{:invalid_variant_name, InvalidModule}]
      end

      assert_raise Factori.InvalidSchemaError, ~r/invalid_variant_name/, fn ->
        InvalidFactory.insert(:invalid_variant_name)
      end
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

      named = UserFactory.insert(:user)
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

      named = UserOverrideFactory.insert(:user)
      assert named.id === "3"
    end

    test "invalid attribute" do
      create_table!(:users, [{:add, :id, :string, [size: 1, null: false]}])

      defmodule UserInvalidOverrideFactory do
        use Factori,
          variants: [{:user, "users"}],
          repo: Factori.TestRepo,
          mappings: [
            [match: fn %{name: :id} -> "1" end]
          ]
      end

      UserInvalidOverrideFactory.bootstrap()

      assert_raise Factori.InvalidAttributeError,
                   ~r/attributes mapping contains invalid keys: \[:foo\]/,
                   fn ->
                     UserInvalidOverrideFactory.insert(:user, foo: "bar")
                   end
    end

    test "list name with override" do
      create_table!(:users, [{:add, :id, :string, [size: 1, null: false]}])

      defmodule ListUserOverrideFactory do
        use Factori,
          repo: Factori.TestRepo,
          variants: [{:user, "users", id: "3"}],
          mappings: [
            [match: fn %{name: :id} -> "1" end]
          ]
      end

      ListUserOverrideFactory.bootstrap()

      [named, _] = ListUserOverrideFactory.insert_list(:user, 2)
      assert named.id === "3"
    end
  end
end
