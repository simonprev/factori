defmodule Factori.Mapping.Faker do
  @behaviour Factori.Mapping

  @ranges %{
    smallint: -32_768..32_767,
    integer: -2_147_483_648..2_147_483_647,
    serial: 1..2_147_483_647,
    bigserial: 1..9_223_372_036_854_775_807
  }
  @timestamps ~w(inserted_at updated_at)a

  alias Faker.Lorem

  def match(%{type: "uuid"}), do: Ecto.UUID.generate()
  def match(%{type: "array"}), do: []
  def match(%{type: "json"}), do: %{}
  def match(%{type: "jsonb"}), do: %{}
  def match(%{type: "int2"}), do: Enum.random(@ranges.smallint)
  def match(%{type: "int4"}), do: Enum.random(@ranges.integer)
  def match(%{type: "int8"}), do: Enum.random(@ranges.bigserial)
  def match(%{type: "float4"}), do: Enum.random(@ranges.serial) * 1.0
  def match(%{type: "float8"}), do: Enum.random(@ranges.bigserial) * 1.0
  def match(%{type: "numeric"}), do: Enum.random(@ranges.bigserial)
  def match(%{type: "bool"}), do: Enum.random([true, false])

  def match(%{type: "text"}), do: Lorem.paragraph(5)
  def match(%{type: "time"}), do: time()
  def match(%{type: "date"}), do: date()
  def match(%{type: "char", options: options}), do: varchar(options)
  def match(%{type: "bytea", options: options}), do: varchar(options)
  def match(%{type: "varchar", name: :email}), do: Faker.Internet.email()
  def match(%{type: "varchar", name: :phone_number}), do: Faker.Phone.EnUs.phone()
  def match(%{type: "_varchar"}), do: []
  def match(%{type: "tsvector"}), do: []

  def match(%{type: "timestamp" <> _, name: name, ecto_type: :utc_datetime})
      when name in @timestamps,
      do: DateTime.truncate(DateTime.utc_now(), :second)

  def match(%{type: "timestamp" <> _, name: name, ecto_type: :naive_datetime})
      when name in @timestamps,
      do: DateTime.to_naive(DateTime.truncate(DateTime.utc_now(), :second))

  def match(%{type: "timestamp" <> _, ecto_type: :utc_datetime}),
    do: DateTime.truncate(timestamp(), :second)

  def match(%{type: "timestamp" <> _, ecto_type: :naive_datetime}),
    do: DateTime.to_naive(DateTime.truncate(timestamp(), :second))

  def match(%{type: "timestamp" <> _, name: name}) when name in @timestamps,
    do: DateTime.utc_now()

  def match(%{type: "timestamp" <> _}), do: timestamp()

  def match(%{type: "varchar", name: name, options: options}) do
    if String.ends_with?(to_string(name), "_id") do
      varchar(options)
    else
      readable_varchar(options)
    end
  end

  def transform(%{ecto_type: :utc_datetime_usec}, value), do: DateTime.add(value, 0, :microsecond)
  def transform(%{ecto_type: :utc_datetime}, value), do: DateTime.truncate(value, :second)

  def transform(_, value), do: value

  defp readable_varchar(options) do
    size = string_max_size(options[:size])
    String.slice(Lorem.sentence(size), 1..size)
  end

  defp varchar(options) do
    size = string_max_size(options[:size])
    String.slice(:base64.encode(:crypto.strong_rand_bytes(size)), 0..(size - 1))
  end

  # If the string has a size greater than 50, we pick a random length from 50 to it’s max size.
  # But we limit the string generation to 500 to not generate too much data for nothing.
  # This is to optimize large string from always generating the largest text
  defp string_max_size(options_size) do
    max_size = min(500, options_size || 255)

    if max_size < 50 do
      max_size
    else
      max(50, trunc(Float.ceil(:rand.uniform() * max_size)))
    end
  end

  defp time do
    DateTime.to_time(timestamp())
  end

  defp date do
    DateTime.to_date(timestamp())
  end

  defp timestamp do
    Faker.DateTime.between(
      Faker.DateTime.backward(10),
      Faker.DateTime.forward(10)
    )
  end
end
