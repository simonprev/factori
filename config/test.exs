import Config

config :factori, Factori.TestRepo,
  pool: Ecto.Adapters.SQL.Sandbox,
  url: System.get_env("DATABASE_URL")

config :logger, level: :info

config :ex_money, default_cldr_backend: Factori.TestCldr
