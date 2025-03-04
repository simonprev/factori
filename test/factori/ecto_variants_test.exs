defmodule Factori.EctoVariantsTest do
  use Factori.EctoCase, async: true

  describe "no variants" do
    test "schema" do
      create_table!(:users, [
        {:add, :name, :string, [size: 1, null: false]}
      ])

      defmodule UserNoVariantsSchema do
        use Ecto.Schema

        @primary_key false
        schema "users" do
          field(:name, :string)
        end
      end

      defmodule UserNoVariantsFactory do
        use Factori,
          repo: Factori.TestRepo,
          mappings: [
            fn
              %{name: :name} -> "a"
            end
          ]
      end

      UserNoVariantsFactory.bootstrap()

      user = UserNoVariantsFactory.insert(UserNoVariantsSchema)
      assert user.__struct__ === UserNoVariantsSchema
      assert user.name === "a"
    end
  end

  describe "variants" do
    test "schema" do
      create_table!(:users, [
        {:add, :id, :string, [size: 1, null: false]},
        {:add, :name, :string, [size: 10, null: false]}
      ])

      defmodule UserSchema do
        use Ecto.Schema

        @primary_key {:id, :string, []}
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

    test "datetimes faker" do
      Code.ensure_compiled!(UserDateTimeSchema)

      create_table!(:users_datetime, [
        {:add, :inserted_at, :utc_datetime, [null: false]},
        {:add, :usec_inserted_at, :utc_datetime_usec, [null: false]}
      ])

      defmodule UserDateTimeFactory do
        use Factori,
          repo: Factori.TestRepo,
          variants: [{:user, UserDateTimeSchema}],
          mappings: [Factori.Mapping.Faker]
      end

      UserDateTimeFactory.bootstrap()

      user = UserDateTimeFactory.insert(:user)
      assert user.__struct__ === UserDateTimeSchema
      assert is_struct(user.inserted_at, DateTime)
      assert is_struct(user.usec_inserted_at, DateTime)
    end

    test "insert list schema overrides" do
      create_table!(:users, [
        {:add, :id, :string, [size: 1, null: false]},
        {:add, :name, :string, [size: 10, null: false]}
      ])

      defmodule UserListOverrideSchema do
        use Ecto.Schema

        @primary_key {:id, :string, []}
        schema "users" do
          field(:name, :string)
        end
      end

      defmodule UserListOverrideFactory do
        use Factori,
          repo: Factori.TestRepo,
          variants: [{:user, UserListOverrideSchema, name: "override"}],
          mappings: [
            fn
              %{name: :id} -> "1"
              %{name: :name} -> "foo"
            end
          ]
      end

      UserListOverrideFactory.bootstrap()

      [named | _] = UserListOverrideFactory.insert_list(:user, 10)
      assert named.__struct__ === UserListOverrideSchema
      assert named.id === "1"
      assert named.name === "override"
    end

    test "schema overrides" do
      create_table!(:users, [
        {:add, :id, :string, [size: 1, null: false]},
        {:add, :name, :string, [size: 10, null: false]}
      ])

      defmodule UserOverrideSchema do
        use Ecto.Schema

        @primary_key {:id, :string, []}
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

    test "schema unknown key" do
      create_table!(:users, [
        {:add, :id, :string, [size: 1, null: false]},
        {:add, :name, :string, [size: 10, null: false]}
      ])

      defmodule UserUnknownOverrideSchema do
        use Ecto.Schema

        @primary_key {:id, :string, []}
        schema "users" do
          field(:name, :string)
        end
      end

      defmodule UserUnknownOverrideFactory do
        use Factori,
          repo: Factori.TestRepo,
          variants: [{:user, UserUnknownOverrideSchema}],
          mappings: [
            fn
              %{name: :id} -> "1"
              %{name: :name} -> "foo"
            end
          ]
      end

      UserUnknownOverrideFactory.bootstrap()

      assert_raise Factori.InvalidAttributeError,
                   ~r/attributes mapping contains invalid keys: \[:foo\]/,
                   fn ->
                     UserUnknownOverrideFactory.insert(:user, foo: "bar")
                   end
    end

    test "key in database not in schema map ecto type" do
      Code.ensure_compiled!(UserDateTimeSchema)

      create_table!(:users_datetime, [
        {:add, :id, :uuid, [null: false]},
        {:add, :inserted_at, :utc_datetime, [null: false]},
        {:add, :usec_inserted_at, :utc_datetime, [null: false]},
        {:add, :deprecated, :boolean, [null: false]}
      ])

      defmodule UserEctoFieldNotUsedInFactory do
        use Factori,
          repo: Factori.TestRepo,
          mappings: [
            fn
              %{name: :deprecated} -> true
              %{name: :id} -> Ecto.UUID.generate()
              %{name: _} -> DateTime.utc_now()
            end
          ]
      end

      UserEctoFieldNotUsedInFactory.bootstrap()

      user = UserEctoFieldNotUsedInFactory.insert(UserDateTimeSchema)
      assert user.__struct__ === UserDateTimeSchema
      refute Map.has_key?(user, :id)
      refute Map.has_key?(user, :deprecated)
      assert is_struct(user.inserted_at, DateTime)
      assert is_struct(user.usec_inserted_at, DateTime)
      assert user.__meta__.state === :loaded
    end

    test "key in database not in schema" do
      create_table!(:users, [
        {:add, :id, :uuid, [null: false]},
        {:add, :other_id, :uuid, [null: false]},
        {:add, :name, :string, [size: 10, null: false]}
      ])

      defmodule UserFieldNotUsedInSchema do
        use Ecto.Schema

        @primary_key {:id, :binary_id, read_after_writes: true}
        schema "users" do
          field(:other_id, Ecto.UUID)
        end
      end

      defmodule UserFieldNotUsedInFactory do
        use Factori,
          repo: Factori.TestRepo,
          variants: [{:user, UserFieldNotUsedInSchema}],
          mappings: [
            fn
              %{name: :other_id} -> Ecto.UUID.generate()
              %{name: :id} -> Ecto.UUID.generate()
              %{name: :name} -> "foo"
            end
          ]
      end

      UserFieldNotUsedInFactory.bootstrap()

      user = UserFieldNotUsedInFactory.insert(:user)
      assert user.__struct__ === UserFieldNotUsedInSchema
      assert user.id
      assert user.other_id
      assert user.__meta__.state === :loaded

      other_user =
        UserFieldNotUsedInFactory.insert(UserFieldNotUsedInSchema,
          id: "d3a26de5-c579-43d2-8089-1b45c3812b82"
        )

      assert other_user.__struct__ === UserFieldNotUsedInSchema
      assert other_user.id === "d3a26de5-c579-43d2-8089-1b45c3812b82"
      assert other_user.other_id
      assert other_user.__meta__.state === :loaded

      # Make sure that the mapping is persisted in the database.
      assert Factori.TestRepo.query!("SELECT name FROM users LIMIT 1").rows === [["foo"]]
    end

    test "schema custom type" do
      create_table!(:users, [
        {:add, :id, :string, [size: 1, null: false]},
        {:add, :uuid_slug, :uuid, [null: false]},
        {:add, :amount, :integer, [null: false]}
      ])

      defmodule UserCustomTypeFactory do
        use Factori,
          repo: Factori.TestRepo,
          variants: [{:user, UserCustomTypeSchema}],
          mappings: [
            fn %{name: :amount} -> Money.new(100, :USD) end,
            Factori.Mapping.Faker
          ]
      end

      UserCustomTypeFactory.bootstrap()

      user = UserCustomTypeFactory.insert(:user)
      assert user.uuid_slug
      assert user.amount === Money.new(100, :USD)
    end

    test "schema json map" do
      create_table!(:users, [
        {:add, :id, :string, [size: 1, null: false]},
        {:add, :data, :jsonb, [null: false]}
      ])

      defmodule UserJSONMapSchema do
        use Ecto.Schema

        @primary_key {:id, :string, []}
        schema "users" do
          field(:data, :map)
        end
      end

      defmodule UserJSONMapFactory do
        use Factori,
          repo: Factori.TestRepo,
          variants: [{:user, UserJSONMapSchema}],
          mappings: [
            fn
              %{name: :id} -> "1"
            end
          ]
      end

      UserJSONMapFactory.bootstrap()

      named = UserJSONMapFactory.insert(:user, %{data: %{"foo" => "test"}})
      assert named.__struct__ === UserJSONMapSchema
      assert named.id === "1"
      assert named.data === %{"foo" => "test"}
    end

    test "schema virtual overrides" do
      create_table!(:users, [
        {:add, :id, :string, [size: 1, null: false]},
        {:add, :name, :string, [size: 10, null: false]}
      ])

      defmodule UserVirtualOverrideSchema do
        use Ecto.Schema

        @primary_key {:id, :string, []}
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
