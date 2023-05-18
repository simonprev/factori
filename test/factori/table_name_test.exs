defmodule Factori.TableNameTest do
  use Factori.EctoCase, async: true

  describe "table name" do
    test "unknown" do
      defmodule UnknownFactory do
        use Factori, repo: Factori.TestRepo
      end

      UnknownFactory.bootstrap()

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

    test "list with override" do
      create_table!(:users, [{:add, :id, :string, [size: 1, null: false]}])

      defmodule ListUserOverrideFactory do
        use Factori,
          repo: Factori.TestRepo,
          mappings: [
            [match: fn %{name: :id} -> "1" end]
          ]
      end

      ListUserOverrideFactory.bootstrap()

      [named, _] = ListUserOverrideFactory.insert_list("users", 2, id: "B")
      assert named.id === "B"
    end

    test "with simple match" do
      create_table!(:users, [{:add, :id, :string, [size: 1, null: false]}])

      defmodule UserSimpleMatchFactory do
        use Factori,
          repo: Factori.TestRepo,
          mappings: [
            fn %{name: :id} -> "1" end
          ]
      end

      UserSimpleMatchFactory.bootstrap()

      named = UserSimpleMatchFactory.insert("users")
      assert named.id === "1"
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

    test "list persist override" do
      create_table!(:users, [{:add, :id, :string, [size: 1, null: false]}])

      defmodule ListUserPersistOverrideFactory do
        use Factori,
          repo: Factori.TestRepo,
          mappings: [
            [match: fn %{name: :id} -> "1" end]
          ]
      end

      ListUserPersistOverrideFactory.bootstrap()

      ListUserPersistOverrideFactory.insert_list("users", 2, id: "B")
      [result_row_1, result_row_2] = Factori.TestRepo.query!("select id from users limit 2").rows
      assert result_row_1 === ["B"]
      assert result_row_2 === ["B"]
    end
  end
end
