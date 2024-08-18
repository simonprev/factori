defmodule Factori.ExMoneyTest do
  use Factori.EctoCase, async: true

  test "nested schema" do
    create_table!(:delivery_methods, [
      {:add, :id, :integer, [primary_key: true, null: false]},
      {:add, :price, :money_with_currency, [null: false]}
    ])

    reference = %Ecto.Migration.Reference{
      name: :delivery_method_id,
      type: :bigint,
      table: :delivery_methods
    }

    create_table!(:products, [
      {:add, :id, :integer, [null: false]},
      {:add, :price, :money_with_currency, [null: false]},
      {:add, :delivery_method_id, reference, [null: false]}
    ])

    defmodule DeliveryMethodSchema do
      use Ecto.Schema

      @primary_key {:id, :string, []}
      schema "delivery_methods" do
        field(:price, Money.Ecto.Composite.Type)
      end
    end

    defmodule ProductSchema do
      use Ecto.Schema

      @primary_key {:id, :string, []}
      schema "products" do
        field(:price, Money.Ecto.Composite.Type)
        belongs_to(:delivery_method, DeliveryMethodSchema)
      end
    end

    defmodule ProductFactory do
      use Factori,
        repo: Factori.TestRepo,
        variants: [product: ProductSchema, delivery_method: DeliveryMethodSchema],
        mappings: [
          fn
            %{name: :id} -> 1
            %{table_name: "products", name: :price} -> Money.new(:EUR, "420.69")
            %{table_name: "delivery_methods", name: :price} -> Money.new(:EUR, "5.00")
          end
        ]
    end

    ProductFactory.bootstrap()

    product = ProductFactory.insert(:product)
    assert product.__struct__ === ProductSchema
    assert product.id == 1
    assert product.price == Money.new(:EUR, "420.69")
    assert product.delivery_method_id
    assert product.delivery_method.price == Money.new(:EUR, "5.00")
  end
end
