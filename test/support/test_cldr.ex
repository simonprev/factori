defmodule Factori.TestCldr do
  @moduledoc """
  See the documentation for Cldr for more info:
  https://hexdocs.pm/ex_cldr
  """
  use Cldr,
    providers: [
      Cldr.Number,
      Money
    ]
end
