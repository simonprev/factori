# Factori

Test data without boilerplate. Always in-sync with your database schema.

```elixir
defmodule MyAppTest.Factory do
  use Factori, repo: MyApp.Repo, mappings: [Factori.Mapping.Faker, Factori.Mapping.Enum]
end

user = MyAppTest.Factory.insert("users")
user.first_name # => "Lorem"
user.last_name # => "Ipsum"
```

## Installation

In `mix.exs`, add the factori dependency:

```elixir
def deps do
  [
    {:factori, "~> 0.1"},
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

### Mappings

Mappings are modules or functions used to map data to columns. `factori` ships with a Faker integration that insert valid data from the type of the column. You can add your own mapper before Faker to override the data mapping:

```elixir
defmodule MyAppTest.MappingCustom do
  @behaviour Factori.Mapping
  def match(%{name: :name}), do: "bar"
end

defmodule MyAppTest.Factory do
  use Factori,
    repo: MyApp.Repo,
    mappings: [fn %{name: :name} -> "foo" end, MappingCustom, Factori.Mapping.Faker]
end

test "mappings" do
  user = Factory.insert("users")
  assert user.name === "foo"
end
```

Mappings also supports transforming data. This can be useful when we want random data but with a bit more control before inserting into the database:
In the example, the custom module does not implement the mapping, so the Faker one is taken. Then, the `transform/2` is called to alter the data.

```elixir
defmodule MyAppTest.Transform do
  @behaviour Factori.Mapping
  def transform(%{name: :password}, value), do: Bcrypt.hash_pwd_salt(value)
end

defmodule MyAppTest.Factory do
  use Factori,
    repo: MyApp.Repo,
    mappings: [Transform, Factori.Mapping.Faker]
end

test "transforms" do
  user = Factory.insert("users", password: "test123")
  assert user.password === "$2b$12$3.EX0EHSwjNewmD18Ir5A.brKyJh3.DCKzLjX96wCwovzie2I1wcW"
end
```

The first module to implement a matching `match` function will be taken, but the `transform` is called on every items in `mappings` options.

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

Ecto struct can also be used directly as variant

```elixir
Factory.insert(MyApp.User)
```

## License

`factori` is © 2023 [Mirego](https://www.mirego.com) and may be freely distributed under the [New BSD license](http://opensource.org/licenses/BSD-3-Clause). See the [`LICENSE.md`](https://github.com/simonprev/factori/blob/master/LICENSE.md) file.

## About Mirego

[Mirego](https://www.mirego.com) is a team of passionate people who believe that work is a place where you can innovate and have fun. We’re a team of [talented people](https://life.mirego.com) who imagine and build beautiful Web and mobile applications. We come together to share ideas and [change the world](http://www.mirego.org).

We also [love open-source software](https://open.mirego.com) and we try to give back to the community as much as we can.
