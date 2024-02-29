defmodule Factori.OptionsTest do
  use Factori.EctoCase, async: true

  describe "nil? match" do
    test "default" do
      create_table!(:users, [
        {:add, :id, :string, [null: true]},
        {:add, :name, :string, [null: false]}
      ])

      defmodule DefaultNullabilityFactory do
        use Factori,
          repo: Factori.TestRepo,
          mappings: [fn _ -> "name" end]
      end

      DefaultNullabilityFactory.bootstrap()

      user = DefaultNullabilityFactory.insert("users")
      refute user.id
      assert user.name
    end

    test "always true" do
      create_table!(:users, [{:add, :id, :string, [null: true]}])

      defmodule NeverNullabilityFactory do
        use Factori,
          repo: Factori.TestRepo,
          null?: [fn _ -> true end],
          mappings: [fn _ -> "1" end]
      end

      NeverNullabilityFactory.bootstrap()

      user = NeverNullabilityFactory.insert("users")
      refute user.id
    end

    test "always false" do
      create_table!(:users, [{:add, :id, :string, [null: true]}])

      defmodule AlwaysNullabilityProbabilityFactory do
        use Factori,
          repo: Factori.TestRepo,
          null?: [fn _ -> false end],
          mappings: [fn _ -> "1" end]
      end

      AlwaysNullabilityProbabilityFactory.bootstrap()

      user = AlwaysNullabilityProbabilityFactory.insert("users")
      assert user.id
    end

    test "column match" do
      create_table!(:users, [
        {:add, :id, :string, [null: true]},
        {:add, :name, :string, [null: true]}
      ])

      defmodule ColumnMatchNullabilityProbabilityFactory do
        use Factori,
          repo: Factori.TestRepo,
          null?: [
            fn %{name: :name} -> false end,
            fn %{name: :id} -> true end
          ],
          mappings: [fn _ -> "1" end]
      end

      ColumnMatchNullabilityProbabilityFactory.bootstrap()

      user = ColumnMatchNullabilityProbabilityFactory.insert("users")
      refute user.id
      assert user.name
    end

    test "module match" do
      create_table!(:users, [
        {:add, :id, :string, [null: true]},
        {:add, :name, :string, [null: true]}
      ])

      defmodule NullModule do
        @behaviour Factori.Null

        def null?(%{name: :name}), do: false
        def null?(%{name: :id}), do: true
      end

      defmodule ModuleNullabilityProbabilityFactory do
        use Factori,
          repo: Factori.TestRepo,
          null?: [NullModule],
          mappings: [fn _ -> "1" end]
      end

      ModuleNullabilityProbabilityFactory.bootstrap()

      user = ModuleNullabilityProbabilityFactory.insert("users")
      refute user.id
      assert user.name
    end
  end
end
