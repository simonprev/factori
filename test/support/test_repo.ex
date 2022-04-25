defmodule Factori.TestRepo do
  use Ecto.Repo,
    otp_app: :factori,
    adapter: Ecto.Adapters.Postgres

  @doc """
  Dynamically loads the repository url from the
  DATABASE_URL environment variable.
  """
  def init(_, opts) do
    {:ok, Keyword.put(opts, :url, Application.get_env(:factori, __MODULE__)[:url])}
  end
end
