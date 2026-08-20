defmodule Factori.Generator do
  @moduledoc """
  Minimal fake data generator.

  Provides only the subset of functionality that `factori` needs. It is not meant
  to produce realistic locale-aware data, only structurally valid values for
  seeding/testing.
  """

  @words ~w(
    lorem ipsum dolor sit amet consectetur adipiscing elit sed do eiusmod tempor
    incididunt ut labore et dolore magna aliqua enim ad minim veniam quis nostrud
    exercitation ullamco laboris nisi aliquip ex ea commodo consequat duis aute
    irure in reprehenderit voluptate velit esse cillum eu fugiat nulla pariatur
  )

  @doc """
  Returns a paragraph made of `count` sentences joined by spaces.
  """
  def paragraph(count) when is_integer(count) and count > 0 do
    Enum.map_join(1..count, " ", fn _ -> sentence(Enum.random(4..10)) end)
  end

  @doc """
  Returns a capitalized sentence made of `word_count` words ending with a period.
  """
  def sentence(word_count) when is_integer(word_count) and word_count > 0 do
    word_count
    |> words()
    |> Enum.join(" ")
    |> String.capitalize()
    |> Kernel.<>(".")
  end

  def sentence(_), do: sentence(1)

  @doc """
  Returns a random email address.
  """
  def email do
    "#{word()}.#{word()}@#{word()}.example.com"
  end

  @doc """
  Returns a random North-American style phone number.
  """
  def phone do
    "#{rand_digits(3)}-#{rand_digits(3)}-#{rand_digits(4)}"
  end

  @doc """
  Returns a random `DateTime` within +/- 10 days of now (microsecond precision).
  """
  def datetime do
    now = System.system_time(:microsecond)
    span = 10 * 24 * 60 * 60 * 1_000_000
    offset = Enum.random(-span..span)
    DateTime.from_unix!(now + offset, :microsecond)
  end

  defp words(count), do: Enum.map(1..count, fn _ -> word() end)

  defp word, do: Enum.random(@words)

  defp rand_digits(n) do
    Enum.map_join(1..n, "", fn _ -> Integer.to_string(Enum.random(0..9)) end)
  end
end
