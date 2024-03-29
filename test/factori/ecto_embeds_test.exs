defmodule Factori.EctoEmbedsTest do
  use Factori.EctoCase, async: true

  describe "string table name" do
    test "insert" do
      Code.ensure_compiled!(UserAddressEmbedSchema)
      Code.ensure_compiled!(UserEmbedSchema)

      create_table!(:users_embed, [
        {:add, :associates, :jsonb, [null: false]},
        {:add, :lead, :jsonb, [null: false]}
      ])

      create_table!(:users_address_embed, [
        {:add, :id, :integer, [null: false]},
        {:add, :street, :string, [null: false]}
      ])

      defmodule UserTableEmbedsMappingFactory do
        use Factori,
          repo: Factori.TestRepo,
          mappings: [Factori.Mapping.Embed, Factori.Mapping.Enum, Factori.Mapping.Faker]
      end

      UserTableEmbedsMappingFactory.bootstrap()

      user = UserTableEmbedsMappingFactory.insert("users_embed")

      assert Factori.TestRepo.get(UserAddressEmbedSchema, user.lead.address_id).street
      assert user.lead.email
      assert is_struct(user.lead.naive_datetime, NaiveDateTime)
      assert is_struct(user.lead.date, Date)
      assert Enum.at(user.associates, 0).name
      assert is_struct(Enum.at(user.associates, 0).other_lead.inserted_at, DateTime)
    end

    test "insert missing mapping" do
      Code.ensure_compiled!(UserAddressEmbedSchema)
      Code.ensure_compiled!(UserEmbedSchema)

      create_table!(:users_embed, [
        {:add, :associates, :jsonb, [null: false]},
        {:add, :lead, :jsonb, [null: false]},
        {:add, :deleted_at, :string, [null: true]}
      ])

      create_table!(:users_address_embed, [
        {:add, :id, :integer, [null: false]},
        {:add, :street, :string, [null: false]}
      ])

      defmodule UserTableEmbedsMissingMappingFactory do
        use Factori,
          repo: Factori.TestRepo,
          mappings: [Factori.Mapping.Embed, Factori.Mapping.Enum, Factori.Mapping.Faker]
      end

      UserTableEmbedsMissingMappingFactory.bootstrap()

      user = UserTableEmbedsMissingMappingFactory.insert(UserEmbedSchema)

      assert user.__struct__ === UserEmbedSchema
      assert Enum.at(user.associates, 0).__struct__ === UserEmbedSchema.Associate

      assert Enum.at(user.associates, 0).other_lead.__struct__ ===
               UserEmbedSchema.Associate.OtherLead

      assert user.lead.__struct__ === UserEmbedSchema.Lead
    end
  end

  describe "embeds faker mapping" do
    test "nested" do
      Code.ensure_compiled!(UserAddressEmbedSchema)
      Code.ensure_compiled!(UserEmbedSchema)

      create_table!(:users_embed, [
        {:add, :associates, :jsonb, [null: false]},
        {:add, :lead, :jsonb, [null: false]}
      ])

      create_table!(:users_address_embed, [
        {:add, :id, :integer, [null: false]},
        {:add, :street, :string, [null: false]}
      ])

      defmodule UserEmbedsMappingFactory do
        use Factori,
          repo: Factori.TestRepo,
          mappings: [Factori.Mapping.Embed, Factori.Mapping.Enum, Factori.Mapping.Faker]
      end

      UserEmbedsMappingFactory.bootstrap()

      user = UserEmbedsMappingFactory.insert(UserEmbedSchema)

      assert user.lead.email
      assert Enum.at(user.associates, 0).name
      assert is_struct(Enum.at(user.associates, 0).other_lead.inserted_at, DateTime)
    end
  end

  describe "embeds_one" do
    test "schema" do
      create_table!(:users, [
        {:add, :contact, :jsonb, [null: false]}
      ])

      defmodule UserEmbedsOneSchema do
        use Ecto.Schema

        @primary_key false
        schema "users" do
          embeds_one :contact, Contact do
            field(:phone, :string)
          end
        end
      end

      defmodule UserEmbedsOneFactory do
        use Factori,
          repo: Factori.TestRepo,
          mappings: [
            [
              match: fn %{name: :contact} ->
                %Factori.EctoEmbedsTest.UserEmbedsOneSchema.Contact{phone: "555-5555"}
              end
            ]
          ]
      end

      UserEmbedsOneFactory.bootstrap()

      user = UserEmbedsOneFactory.insert(UserEmbedsOneSchema)
      assert user.__struct__ === UserEmbedsOneSchema
      assert user.contact.__struct__ === UserEmbedsOneSchema.Contact
      assert user.contact.phone === "555-5555"
    end

    test "schema embed in reference" do
      create_table!(:reference_users, [
        {
          :add,
          :id,
          :integer,
          [primary_key: true, null: false]
        },
        {:add, :tag, :jsonb, [null: false]}
      ])

      reference = %Ecto.Migration.Reference{
        name: :author_id,
        type: :bigint,
        table: :reference_users
      }

      create_table!(:reference_posts, [
        {:add, :author_id, reference, [null: false]}
      ])

      defmodule UserReferenceEmbedsOneSchema do
        use Ecto.Schema

        schema "reference_users" do
          embeds_one :tag, Tag do
            field(:name, :string)
          end
        end
      end

      defmodule PostReferenceEmbedsOneSchema do
        use Ecto.Schema

        @primary_key false
        schema "reference_posts" do
          belongs_to(:author, UserReferenceEmbedsOneSchema)
        end
      end

      defmodule UserReferenceEmbedsOneFactory do
        use Factori,
          repo: Factori.TestRepo,
          mappings: [
            [match: fn %{name: :id} -> 1 end],
            [
              match: fn %{name: :tag} ->
                %Factori.EctoEmbedsTest.UserReferenceEmbedsOneSchema.Tag{name: "foo"}
              end
            ]
          ]
      end

      UserReferenceEmbedsOneFactory.bootstrap()

      post = UserReferenceEmbedsOneFactory.insert(PostReferenceEmbedsOneSchema)
      post = Factori.TestRepo.preload(post, :author)

      assert post.author.__struct__ === UserReferenceEmbedsOneSchema
      assert post.author.tag.__struct__ === UserReferenceEmbedsOneSchema.Tag
      assert post.author.tag.name === "foo"
    end

    test "schema list" do
      create_table!(:users, [
        {:add, :contact, :jsonb, [null: false]}
      ])

      defmodule UserListEmbedsOneSchema do
        use Ecto.Schema

        @primary_key false
        schema "users" do
          embeds_one :contact, Contact do
            field(:phone, :string)
          end
        end
      end

      defmodule UserListEmbedsOneFactory do
        use Factori,
          repo: Factori.TestRepo,
          mappings: [
            [
              match: fn %{name: :contact} ->
                %Factori.EctoEmbedsTest.UserListEmbedsOneSchema.Contact{phone: "555-5555"}
              end
            ]
          ]
      end

      UserListEmbedsOneFactory.bootstrap()

      [user | _] = UserListEmbedsOneFactory.insert_list(UserListEmbedsOneSchema, 2)
      assert user.__struct__ === UserListEmbedsOneSchema
      assert user.contact.__struct__ === UserListEmbedsOneSchema.Contact
      assert user.contact.phone === "555-5555"
    end
  end
end
