defmodule Factori.TableNameTest do
  use Factori.EctoCase, async: true

  describe "table name" do
    test "unknown" do
      defmodule UnknownFactory do
        use Factori, repo: Factori.TestRepo
      end

      assert_raise Factori.UndefinedTableError, ~r/foo/, fn ->
        UnknownFactory.insert("foo")
      end
    end

    test "with override" do
      create_table!(:users, [{:add, :id, :string, [size: 1, null: false]}])

      defmodule UserOverrideFactory do
        use Factori,
          repo: Factori.TestRepo,
          mappings: [
            [match: fn %{name: :id} -> "1" end]
          ]
      end

      UserOverrideFactory.bootstrap()

      named = UserOverrideFactory.insert("users", id: "B")
      assert named.id === "B"
    end

    test "persist override" do
      create_table!(:users, [{:add, :id, :string, [size: 1, null: false]}])

      defmodule UserPersistOverrideFactory do
        use Factori,
          repo: Factori.TestRepo,
          mappings: [
            [match: fn %{name: :id} -> "1" end]
          ]
      end

      UserPersistOverrideFactory.bootstrap()

      UserPersistOverrideFactory.insert("users", id: "B")
      [result_row] = Factori.TestRepo.query!("select id from users limit 1").rows
      assert result_row === ["B"]
    end
  end
end
