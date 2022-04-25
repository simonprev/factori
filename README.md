# Factori

## Installation

**To install in all environments (useful for generating seed data in dev/prod):**

In `mix.exs`, add the ExMachina dependency:

```elixir
def deps do
  [
    {:factori, "~> 0.0.1"},
  ]
end
```

## Overview

Define your `Factory` module with the repo (typically in `test/support`).

```elixir
defmodule MyAppTest.Factory do
  use Factori, repo: MyApp.Repo, mappings: [Factori.Mapping.Faker]
end
```
