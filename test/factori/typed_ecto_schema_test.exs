defmodule Factori.TypedEctoSchemaTest do
  use Factori.EctoCase, async: true

  test "schema" do
    create_table!(:users, [
      {:add, :id, :string, [size: 1, null: false]},
      {:add, :name, :string, [size: 10, null: false]}
    ])

    defmodule UserSchema do
      use TypedEctoSchema

      @primary_key {:id, :string, []}
      typed_schema "users" do
        field(:name, :string)
      end
    end

    defmodule TypedUserFactory do
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

    TypedUserFactory.bootstrap()

    named = TypedUserFactory.insert(:user)
    assert named.__struct__ === UserSchema
    assert named.id === "1"
    assert named.name === "foo"
  end
end
