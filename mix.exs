defmodule Factori.Mixfile do
  use Mix.Project

  def project do
    [
      app: :factori,
      version: "0.9.1",
      elixir: ">= 1.12.0",
      description: "Test factories generated from database schema",
      elixirc_paths: elixirc_paths(Mix.env()),
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      package: package(),
      docs: [main: "readme", extras: ["README.md"]],
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:ex_doc, "~> 0.14", only: :dev},
      {:earmark, ">= 0.0.0", only: :dev},
      {:faker, "~> 0.16"},
      {:ecto, "~> 3.0"},
      {:ecto_sql, "~> 3.0"},
      {:jason, "~> 1.0", only: [:dev, :test]},
      {:postgrex, "~> 0.14", only: :test},
      {:dialyxir, "~> 1.0", only: [:dev, :test], runtime: false},
      {:typed_ecto_schema, "~> 0.4.1", only: :test, runtime: false},
      {:credo, "~> 1.1", only: [:dev, :test], override: true},
      {:credo_envvar, "~> 0.1", only: [:dev, :test], runtime: false},
      {:credo_naming, "~> 1.0", only: [:dev, :test], runtime: false}
    ]
  end

  defp package do
    [
      maintainers: ["Simon Prévost"],
      licenses: ["MIT"],
      links: %{
        GitHub: "https://github.com/simonprev/factori"
      }
    ]
  end

  defp elixirc_paths(:test), do: elixirc_paths() ++ ["test/support"]
  defp elixirc_paths(_), do: elixirc_paths()
  defp elixirc_paths, do: ["lib"]
end
