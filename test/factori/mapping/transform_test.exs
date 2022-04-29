defmodule Factori.Mapping.TransformTest do
  use Factori.EctoCase, async: true

  describe "transform" do
    test "module" do
      create_table!(:users, [
        {:add, :name, :string, [size: 255, null: false]}
      ])

      defmodule TransformModule do
        @behaviour Factori.Mapping

        def match(_), do: "my name"
        def transform(_, value), do: String.upcase(value)
      end

      defmodule TransformModuleFactory do
        use Factori,
          repo: Factori.TestRepo,
          variants: [{:user, "users"}],
          mappings: [TransformModule]
      end

      TransformModuleFactory.bootstrap()

      user = TransformModuleFactory.insert("users")
      assert user.name === "MY NAME"
    end

    test "inline" do
      create_table!(:users, [
        {:add, :name, :string, [size: 255, null: false]}
      ])

      defmodule TranformInlineFactory do
        use Factori,
          repo: Factori.TestRepo,
          variants: [{:user, "users"}],
          mappings: [
            [match: fn _ -> "my name" end, transform: fn _, value -> String.upcase(value) end]
          ]
      end

      TranformInlineFactory.bootstrap()

      user = TranformInlineFactory.insert("users")
      assert user.name === "MY NAME"
    end
  end
end
