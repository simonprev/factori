defmodule Factori.StructVariantsTest do
  use Factori.EctoCase, async: true

  describe "variants" do
    test "structs" do
      create_table!(:users, [{:add, :id, :string, [size: 1, null: false]}])

      defmodule UserStruct do
        defstruct id: nil
      end

      defmodule UserFactory do
        use Factori,
          repo: Factori.TestRepo,
          variants: [{:user, "users", UserStruct}],
          mappings: [
            fn %{name: :id} -> "1" end
          ]
      end

      UserFactory.bootstrap()

      named = UserFactory.insert(:user)
      assert named.__struct__ === UserStruct
      assert named.id === "1"
    end

    test "struct with override" do
      create_table!(:users, [{:add, :id, :string, [size: 1, null: false]}])

      defmodule UserOverrideStruct do
        defstruct id: nil
      end

      defmodule UserOverrideFactory do
        use Factori,
          repo: Factori.TestRepo,
          variants: [{:user, "users", UserOverrideStruct, id: "3"}],
          mappings: [
            fn %{name: :id} -> "1" end
          ]
      end

      UserOverrideFactory.bootstrap()

      named = UserOverrideFactory.insert(:user)
      assert named.__struct__ === UserOverrideStruct
      assert named.id === "3"
    end

    test "list struct with override" do
      create_table!(:users, [{:add, :id, :string, [size: 1, null: false]}])

      defmodule ListUserOverrideStruct do
        defstruct id: nil
      end

      defmodule ListUserOverrideFactory do
        use Factori,
          repo: Factori.TestRepo,
          variants: [{:user, "users", ListUserOverrideStruct, id: "3"}],
          mappings: [
            fn %{name: :id} -> "1" end
          ]
      end

      ListUserOverrideFactory.bootstrap()

      [named, _] = ListUserOverrideFactory.insert_list(:user, 2)
      assert named.__struct__ === ListUserOverrideStruct
      assert named.id === "3"
    end
  end
end
