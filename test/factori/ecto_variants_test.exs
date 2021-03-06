defmodule Factori.EctoVariantsTest do
  use Factori.EctoCase, async: true

  describe "variants" do
    test "schema" do
      create_table!(:users, [
        {:add, :id, :string, [size: 1, null: false]},
        {:add, :name, :string, [size: 10, null: false]}
      ])

      defmodule UserSchema do
        use Ecto.Schema

        schema "users" do
          field(:name, :string)
        end
      end

      defmodule UserFactory do
        use Factori,
          repo: Factori.TestRepo,
          variants: [{:user, UserSchema}],
          mappings: [
            fn
              %{name: :id} -> "1"
              %{name: :name} -> "foo"
            end
          ]
      end

      UserFactory.bootstrap()

      named = UserFactory.insert(:user)
      assert named.__struct__ === UserSchema
      assert named.id === "1"
      assert named.name === "foo"
    end

    test "schema overrides" do
      create_table!(:users, [
        {:add, :id, :string, [size: 1, null: false]},
        {:add, :name, :string, [size: 10, null: false]}
      ])

      defmodule UserOverrideSchema do
        use Ecto.Schema

        schema "users" do
          field(:name, :string)
        end
      end

      defmodule UserOverrideFactory do
        use Factori,
          repo: Factori.TestRepo,
          variants: [{:user, UserOverrideSchema, name: "override"}],
          mappings: [
            fn
              %{name: :id} -> "1"
              %{name: :name} -> "foo"
            end
          ]
      end

      UserOverrideFactory.bootstrap()

      named = UserOverrideFactory.insert(:user)
      assert named.__struct__ === UserOverrideSchema
      assert named.id === "1"
      assert named.name === "override"
    end

    test "schema virtual overrides" do
      create_table!(:users, [
        {:add, :id, :string, [size: 1, null: false]},
        {:add, :name, :string, [size: 10, null: false]}
      ])

      defmodule UserVirtualOverrideSchema do
        use Ecto.Schema

        schema "users" do
          field(:name, :string)
          field(:admin?, :boolean, virtual: true)
        end
      end

      defmodule UserVirtualOverrideFactory do
        use Factori,
          repo: Factori.TestRepo,
          variants: [{:user, UserVirtualOverrideSchema, admin?: true}],
          mappings: [
            fn
              %{name: :id} -> "1"
              %{name: :name} -> "foo"
            end
          ]
      end

      UserVirtualOverrideFactory.bootstrap()

      named = UserVirtualOverrideFactory.insert(:user)
      assert named.__struct__ === UserVirtualOverrideSchema
      assert named.id === "1"
      assert named.name === "foo"
      assert named.admin?
    end
  end
end
