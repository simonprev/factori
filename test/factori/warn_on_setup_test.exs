defmodule Factori.WarnOnSetupTest do
  use Factori.EctoCase, async: false

  import ExUnit.CaptureLog

  describe "pool_size" do
    test "less than 1" do
      defmodule PoolSize1Factory do
        use Factori, repo: Factori.TestRepo
      end

      Application.put_env(:factori, Factori.TestRepo, pool_size: 1)
      log = capture_log(fn -> PoolSize1Factory.bootstrap() end)

      assert log =~
               "Factori.TestRepo :pool_size option should be greater than 1 to allow bootstraping and running tests concurrently, got: 1"
    end
  end
end
