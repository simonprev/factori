defmodule Factori.TypesTest do
  use Factori.EctoCase, async: false

  import Ecto.Query

  alias Factori.TestRepo, as: Repo

  defmodule CustomFactoryMapping do
    @behaviour Factori.Mapping

    def match(%{name: :custom_string}), do: "custom name"
    def match(%{type: "text"}), do: "custom text"
  end

  defmodule NamedSchema do
    defstruct id: nil
  end

  defmodule NamedEctoSchema do
    use Ecto.Schema

    schema "users" do
      field(:name, :string)
    end
  end

  defmodule Factory do
    use Factori,
      repo: Factori.TestRepo,
      mappings: [CustomFactoryMapping, Factori.Mapping.Faker],
      variants: [
        {:awesome, "users", NamedSchema},
        {:ecto_named, NamedEctoSchema},
        {:invalid_variant, NamedSchema},
        {:named, "users"},
        {:variant_named, "users", name: "variant"},
        {:ecto_variant_named, NamedEctoSchema, name: "variant"}
      ]
  end

  def table!(action, name, columns) do
    Ecto.Adapters.Postgres.Connection.execute_ddl({
      action,
      %Ecto.Migration.Table{name: name, prefix: :public},
      columns
    })
    |> IO.iodata_to_binary()
    |> Factori.TestRepo.query!()
    |> then(fn _ -> refresh_storage!() end)
  end

  def refresh_storage! do
    Factory.bootstrap()
  end

  def row_for_type(type) do
    table!(:create, :table, [{:add, :field, type, [null: false]}])
    Factory.insert("table")
  end

  describe "variants" do
    test "unknown" do
      assert_raise Factori.UndefinedVariantError, ~r/foo/, fn ->
        Factory.insert(:foo)
      end
    end

    test "invalid schema" do
      assert_raise Factori.InvalidSchemaError, ~r/invalid_variant/, fn ->
        Factory.insert(:invalid_variant)
      end
    end

    test "schemas" do
      table!(:create, :users, [
        {:add, :id, :string, [size: 1, null: false]}
      ])

      named = Factory.insert(:awesome)
      assert named.__struct__ === NamedSchema
      assert named.id
    end

    test "simple" do
      table!(:create, :users, [
        {:add, :id, :string, [size: 1, null: false]}
      ])

      named = Factory.insert(:named)
      assert named.id
    end

    test "overrides" do
      table!(:create, :users, [
        {:add, :id, :string, [size: 1, null: false]}
      ])

      named = Factory.insert(:awesome, id: "A")
      assert named.__struct__ === NamedSchema
      assert named.id === "A"
    end

    test "ecto" do
      table!(:create, :users, [
        {:add, :id, :string, [size: 255, null: false]},
        {:add, :name, :string, [size: 5, null: false]}
      ])

      named = Factory.insert(:ecto_named, name: "A")
      assert named.__struct__ === NamedEctoSchema
      assert named.name === "A"
    end

    test "ecto variant" do
      table!(:create, :users, [
        {:add, :id, :string, [size: 255, null: false]},
        {:add, :name, :string, [size: 255, null: false]}
      ])

      named = Factory.insert(:ecto_variant_named)
      assert named.__struct__ === NamedEctoSchema
      assert named.name === "variant"
    end

    test "variant" do
      table!(:create, :users, [
        {:add, :name, :string, [size: 255, null: false]}
      ])

      named = Factory.insert(:variant_named)
      assert named.name === "variant"
    end
  end

  describe "struct" do
    defmodule UserSchema do
      defstruct email: nil, name: nil
    end

    test "exact map" do
      table!(:create, :users, [
        {:add, :email, :string, [size: 1, null: false]}
      ])

      user = Factory.insert("users", UserSchema)
      assert user.__struct__ === UserSchema
      assert user.email
    end

    test "unknown fields" do
      table!(:create, :users, [
        {:add, :email, :string, [size: 1, null: false]},
        {:add, :password, :string, [size: 1, null: false]}
      ])

      user = Factory.insert("users", UserSchema)
      assert user.__struct__ === UserSchema
      assert user.email
    end

    test "overrides" do
      table!(:create, :users, [
        {:add, :name, :string, [size: 255, null: false]},
        {:add, :email, :string, [size: 1, null: false]}
      ])

      user = Factory.insert("users", UserSchema, name: "foo")
      assert user.__struct__ === UserSchema
      assert user.email
      assert user.name === "foo"
    end
  end

  describe "types" do
    test "limit" do
      table!(:create, :users, [
        {:add, :name, :string, [size: 1, null: false]}
      ])

      user = Factory.insert("users")
      assert user.name
    end

    test "reuse reference" do
      table!(:create, :users, [
        {:add, :id, :integer, [primary_key: true, null: false]}
      ])

      author_reference = %Ecto.Migration.Reference{name: :author_id, type: :bigint, table: :users}
      owner_reference = %Ecto.Migration.Reference{name: :owner_id, type: :bigint, table: :users}

      other_user_reference = %Ecto.Migration.Reference{
        name: :other_user_id,
        type: :bigint,
        table: :users
      }

      table!(:create, :posts, [
        {:add, :id, :integer, [primary_key: true, null: false]},
        {:add, :author_id, author_reference, [null: false]},
        {:add, :other_user_id, other_user_reference, [null: false]},
        {:add, :owner_id, owner_reference, [null: false]}
      ])

      post = Factory.insert("posts")
      assert post.author_id === post.owner_id
    end

    test "double reference" do
      table!(:create, :users, [
        {:add, :id, :integer, [primary_key: true, null: false]}
      ])

      user_reference = %Ecto.Migration.Reference{name: :author_id, type: :bigint, table: :users}

      table!(:create, :posts, [
        {:add, :id, :integer, [primary_key: true, null: false]},
        {:add, :author_id, user_reference, [null: false]}
      ])

      post_reference = %Ecto.Migration.Reference{
        name: :last_post_id,
        type: :bigint,
        table: :posts
      }

      table!(:alter, :users, [{:add, :last_post_id, post_reference, [null: false]}])

      assert_raise Factori.Attributes.CyclicNonNullableReferenceError, fn ->
        Factory.insert("posts")
      end
    end

    test "custom mappings" do
      table!(:create, :users, [
        {:add, :custom_string, :string, [null: false]},
        {:add, :custom_type, :text, [null: false]}
      ])

      user = Factory.insert("users")

      assert user.custom_string === "custom name"
      assert user.custom_type === "custom text"
    end

    test "reference" do
      table!(:create, :users, [{:add, :id, :integer, [primary_key: true, null: false]}])

      reference = %Ecto.Migration.Reference{name: :author_id, type: :bigint, table: :users}
      table!(:create, :posts, [{:add, :author_id, reference, [null: false]}])

      post = Factory.insert("posts")
      [%{id: user_id}] = Repo.all(from("users", select: [:id]))

      assert post.author_id === user_id
    end

    test "string" do
      row = row_for_type(:string)
      assert is_binary(row.field)
    end

    test "boolean" do
      row = row_for_type(:boolean)
      assert is_boolean(row.field)
    end

    test "integer" do
      row = row_for_type(:integer)
      assert is_integer(row.field)
    end

    test "inline factory" do
      defmodule InlineMatchFactory do
        use Factori, repo: Factori.TestRepo
        def match(_), do: "inline"
      end

      table!(:create, :table, [{:add, :field, :string, [null: false]}])
      row = InlineMatchFactory.insert("table")
      assert row.field === "inline"
    end
  end
end
