defmodule Factori.EctoCase do
  use ExUnit.CaseTemplate

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Factori.TestRepo)
  end
end
