defmodule Factori.Mapping.FakerTest do
  use Factori.EctoCase, async: true

  describe "faker" do
    test "limit" do
      create_table!(:users, [
        {:add, :name, :string, [size: 1, null: false]}
      ])

      defmodule LimitFactory do
        use Factori,
          repo: Factori.TestRepo,
          variants: [{:user, "users"}],
          mappings: [Factori.Mapping.Faker]
      end

      LimitFactory.bootstrap()

      user = LimitFactory.insert("users")
      assert String.length(user.name) === 1
    end

    test "types" do
      columns = for type <- ~w(
        id
        binary_id
        integer
        float
        boolean
        string
        binary
        map
        decimal
        date
        time
        time_usec
        naive_datetime
        naive_datetime_usec
        utc_datetime
        utc_datetime_usec
      )a, into: [], do: {:add, type, type, [null: false]}

      create_table!(:users, columns)

      defmodule TypesFactory do
        use Factori,
          repo: Factori.TestRepo,
          mappings: [Factori.Mapping.Faker]
      end

      TypesFactory.bootstrap()

      user = TypesFactory.insert("users")

      assert is_integer(user.id)
      assert is_binary(user.binary_id)
      assert is_float(user.float)
      assert is_boolean(user.boolean)
      assert is_binary(user.string)
      assert is_binary(user.binary)
      assert is_map(user.map)
      assert is_struct(user.decimal, Decimal)
      assert is_struct(user.date, Date)
      assert is_struct(user.time, Time)
      assert is_struct(user.time_usec, Time)
      assert is_struct(user.naive_datetime, NaiveDateTime)
      assert is_struct(user.naive_datetime_usec, NaiveDateTime)
      assert is_struct(user.utc_datetime, NaiveDateTime)
      assert is_struct(user.utc_datetime_usec, NaiveDateTime)
    end
  end
end
