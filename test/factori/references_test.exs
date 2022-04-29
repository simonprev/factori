defmodule Factori.ReferencesTest do
  use Factori.EctoCase, async: true

  alias Factori.TestRepo, as: Repo

  describe "references" do
    test "reference" do
      create_table!(:reference_users, [{:add, :id, :integer, [primary_key: true, null: false]}])

      reference = %Ecto.Migration.Reference{
        name: :author_id,
        type: :bigint,
        table: :reference_users
      }

      create_table!(:reference_posts, [{:add, :author_id, reference, [null: false]}])

      defmodule ReferenceFactory do
        use Factori,
          repo: Factori.TestRepo,
          mappings: [Factori.Mapping.Faker]
      end

      ReferenceFactory.bootstrap()

      post = ReferenceFactory.insert("reference_posts")

      import Ecto.Query
      [%{id: user_id}] = Repo.all(from("reference_users", select: [:id]))

      assert post.author_id === user_id
    end

    test "reuse reference" do
      create_table!(:reuse_reference_users, [
        {:add, :id, :integer, [primary_key: true, null: false]}
      ])

      author_reference = %Ecto.Migration.Reference{
        name: :author_id,
        type: :bigint,
        table: :reuse_reference_users
      }

      owner_reference = %Ecto.Migration.Reference{
        name: :owner_id,
        type: :bigint,
        table: :reuse_reference_users
      }

      other_user_reference = %Ecto.Migration.Reference{
        name: :other_user_id,
        type: :bigint,
        table: :reuse_reference_users
      }

      create_table!(:reuse_reference_posts, [
        {:add, :id, :integer, [primary_key: true, null: false]},
        {:add, :author_id, author_reference, [null: false]},
        {:add, :other_user_id, other_user_reference, [null: false]},
        {:add, :owner_id, owner_reference, [null: false]}
      ])

      defmodule ReuseFactory do
        use Factori,
          repo: Factori.TestRepo,
          mappings: [Factori.Mapping.Faker]
      end

      ReuseFactory.bootstrap()

      post = ReuseFactory.insert("reuse_reference_posts")
      assert post.author_id === post.owner_id
    end

    test "double reference" do
      create_table!(:users, [
        {:add, :id, :integer, [primary_key: true, null: false]}
      ])

      user_reference = %Ecto.Migration.Reference{name: :author_id, type: :bigint, table: :users}

      create_table!(:posts, [
        {:add, :id, :integer, [primary_key: true, null: false]},
        {:add, :author_id, user_reference, [null: false]}
      ])

      post_reference = %Ecto.Migration.Reference{
        name: :last_post_id,
        type: :bigint,
        table: :posts
      }

      alter_table!(:users, [{:add, :last_post_id, post_reference, [null: false]}])

      defmodule DoubleFactory do
        use Factori,
          repo: Factori.TestRepo,
          mappings: [Factori.Mapping.Faker]
      end

      DoubleFactory.bootstrap()

      assert_raise Factori.Attributes.CyclicNonNullableReferenceError, fn ->
        DoubleFactory.insert("posts")
      end
    end
  end
end
