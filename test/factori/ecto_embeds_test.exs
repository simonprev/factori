defmodule Factori.EctoEmbedsTest do
  use Factori.EctoCase, async: true

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
