# Factori

## Installation

**To install in all environments (useful for generating seed data in dev/prod):**

In `mix.exs`, add the Factory dependency:

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

Initialize the module by checking out the `Repo` and boostraping the `Factory`.

This is typically done in `data_case.ex`.

```elixir
setup_all do
  :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)
  Ecto.Adapters.SQL.Sandbox.mode(Repo, {:shared, self()})

  MyApp.Factory.bootstrap()
  :ok
end
```

## Usage

In a test case, just use your `Factory` module by referencing the table name

```elixir
test "insert user" do
  user = Factory.insert("users")
  assert user.id
end
```

### Overrides

```elixir
test "insert user with overrides" do
  user = Factory.insert("users", name: "Test")
  assert user.name === "Test"
end
```

### Variants

Instead of using string to reference the "raw" table names, you can use named variants:

```elixir
defmodule MyAppTest.Factory do
  use Factori,
    repo: MyApp.Repo,
    mappings: [Factori.Mapping.Faker],
    variants: [{:user, "users"}]
end

MyAppTest.Factory.insert(:user)
MyAppTest.Factory.insert(:user, name: "Test")
```

Variants can also include overrides:

```elixir
defmodule MyAppTest.Factory do
  use Factori,
    repo: MyApp.Repo,
    mappings: [Factori.Mapping.Faker],
    variants: [{:user, "users", name: "Test"}]
end

test "insert user with overrides" do
  user = Factory.insert(:user)
  assert user.name === "Test"

  user = Factory.insert(:user, name: "123")
  assert user.name === "123"
end
```

## Ecto and structs

```elixir
defmodule MyApp.User do
  use Ecto.Schema

  schema "users" do
    field(:name, :string)
    field(:admin, :boolean)
  end
end

defmodule MyAppTest.Factory do
  use Factori,
    repo: MyApp.Repo,
    mappings: [Factori.Mapping.Faker],
    variants: [{:user, MyApp.User}, {:admin, MyApp.User, admin: true}]
end

test "insert ecto schema" do
  user = Factory.insert(:user)
  assert user.name

  admin = Factory.insert(:admin)
  assert admin.admin
end
```
