defmodule Factori.OptionsTest do
  use Factori.EctoCase, async: true

  describe "nil_probability" do
    test "0" do
      create_table!(:users, [{:add, :id, :string, [null: true]}])

      defmodule NeverNilProbabilityFactory do
        use Factori,
          repo: Factori.TestRepo,
          options: [nil_probability: 1],
          mappings: [fn _ -> "1" end]
      end

      NeverNilProbabilityFactory.bootstrap()

      user = NeverNilProbabilityFactory.insert("users")
      refute user.id
    end

    test "1" do
      create_table!(:users, [{:add, :id, :string, [null: true]}])

      defmodule AlwaysNilProbabilityFactory do
        use Factori,
          repo: Factori.TestRepo,
          options: [nil_probability: 0],
          mappings: [fn _ -> "1" end]
      end

      AlwaysNilProbabilityFactory.bootstrap()

      user = AlwaysNilProbabilityFactory.insert("users")
      assert user.id
    end
  end
end
