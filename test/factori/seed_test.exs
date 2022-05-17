defmodule Factori.SeedTest do
  require Logger
  use Factori.EctoCase, async: true

  describe "seed" do
    test "unknown" do
      defmodule UnknownFactory do
        use Factori, repo: Factori.TestRepo
      end

      assert_raise Factori.UndefinedVariantError, ~r/foo/, fn ->
        UnknownFactory.seed(:foo)
      end
    end

    test "invalid schema" do
      defmodule InvalidModule do
      end

      defmodule InvalidFactory do
        use Factori, repo: Factori.TestRepo, variants: [{:invalid_variant_name, InvalidModule}]
      end

      assert_raise Factori.InvalidSchemaError, ~r/invalid_variant_name/, fn ->
        InvalidFactory.seed(:invalid_variant_name)
      end
    end

    test "name" do
      create_table!(:users, [{:add, :id, :string, [size: 1, null: false]}])

      defmodule UserFactory do
        use Factori,
          repo: Factori.TestRepo,
          variants: [{:user, "users"}],
          mappings: [
            [match: fn %{name: :id} -> "1" end]
          ]
      end

      UserFactory.bootstrap()

      :ok = UserFactory.seed(:user)
      user_ids = List.flatten(query!("select id from users"))
      assert length(user_ids) === 1
    end

    test "count" do
      create_table!(:users, [{:add, :id, :string, [size: 1, null: false]}])

      defmodule CountUserFactory do
        use Factori,
          repo: Factori.TestRepo,
          variants: [{:user, "users"}],
          mappings: [
            [match: fn %{name: :id} -> "1" end]
          ]
      end

      CountUserFactory.bootstrap()

      :ok = CountUserFactory.seed(:user, 10)
      user_ids = List.flatten(query!("select id from users"))
      assert length(user_ids) === 10
    end

    test "large count" do
      create_table!(:users, [{:add, :id, :string, [size: 1, null: false]}])

      defmodule LargeCountUserFactory do
        use Factori,
          repo: Factori.TestRepo,
          mappings: [
            fn _ -> "1" end
          ]
      end

      LargeCountUserFactory.bootstrap()

      {time_microseconds, :ok} = :timer.tc(fn -> LargeCountUserFactory.seed("users", 100_000) end)
      user_ids = List.flatten(query!("select id from users"))

      Logger.info("Inserting 100 000 simple rows took #{time_microseconds / 1000} milliseconds")

      # Execution time is less than 1 second
      assert time_microseconds < 1_000_000

      assert length(user_ids) === 100_000
    end

    test "very large count" do
      create_table!(:users, [{:add, :id, :string, [size: 1, null: false]}])

      defmodule VeryLargeCountUserFactory do
        use Factori,
          repo: Factori.TestRepo,
          mappings: [
            fn _ -> "1" end
          ]
      end

      VeryLargeCountUserFactory.bootstrap()

      {time_microseconds, :ok} =
        :timer.tc(fn -> VeryLargeCountUserFactory.seed("users", 500_000) end)

      Logger.info("Inserting 500 000 simple rows took #{time_microseconds / 1_000_000} seconds")

      # Execution time is less than 5 seconds
      assert time_microseconds < 5_000_000
    end
  end
end
