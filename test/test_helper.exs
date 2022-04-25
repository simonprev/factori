Mix.Task.run("ecto.drop", ["quiet", "-r", "Factori.TestRepo"])
Mix.Task.run("ecto.create", ["quiet", "-r", "Factori.TestRepo"])

Factori.TestRepo.start_link()
ExUnit.start()

Ecto.Adapters.SQL.Sandbox.mode(Factori.TestRepo, :manual)
