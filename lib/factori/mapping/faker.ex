defmodule Factori.Mapping.Faker do
  @behaviour Factori.Mapping

  @ranges %{
    smallint: -32_768..32_767,
    integer: -2_147_483_648..2_147_483_647,
    serial: 1..2_147_483_647,
    bigserial: 1..9_223_372_036_854_775_807
  }
  @timestamps ~w(inserted_at updated_at)

  alias Faker.Lorem

  def match(%{type: "uuid"}), do: Ecto.UUID.generate()
  def match(%{type: "json"}), do: %{}
  def match(%{type: "jsonb"}), do: %{}
  def match(%{type: "int2"}), do: Enum.random(@ranges.smallint)
  def match(%{type: "int4"}), do: Enum.random(@ranges.integer)
  def match(%{type: "int8"}), do: Enum.random(@ranges.bigserial)
  def match(%{type: "float4"}), do: Enum.random(@ranges.serial)
  def match(%{type: "float8"}), do: Enum.random(@ranges.bigserial)
  def match(%{type: "numeric"}), do: Enum.random(@ranges.bigserial)
  def match(%{type: "bool"}), do: Enum.random([true, false])

  def match(%{type: "text"}), do: Lorem.paragraph(5)
  def match(%{type: "time"}), do: time()
  def match(%{type: "date"}), do: date()
  def match(%{type: "char", options: options}), do: varchar(options)
  def match(%{type: "bytea", options: options}), do: varchar(options)
  def match(%{type: "varchar", name: "email"}), do: Faker.Internet.email()
  def match(%{type: "varchar", name: "phone_number"}), do: Faker.Phone.EnUs.phone()

  def match(%{type: "timestamp", name: name, ecto_type: :utc_datetime}) when name in @timestamps,
    do: DateTime.truncate(DateTime.utc_now(), :second)

  def match(%{type: "timestamp", ecto_type: :utc_datetime}),
    do: DateTime.truncate(timestamp(), :second)

  def match(%{type: "timestamp", name: name}) when name in @timestamps, do: DateTime.utc_now()
  def match(%{type: "timestamp"}), do: timestamp()

  def match(%{type: "timestampz", name: name, ecto_type: :utc_datetime}) when name in @timestamps,
    do: DateTime.truncate(timestamp(), :second)

  def match(%{type: "timestampz", ecto_type: :utc_datetime}),
    do: DateTime.truncate(timestamp(), :second)

  def match(%{type: "timestampz", name: name}) when name in @timestamps, do: DateTime.utc_now()
  def match(%{type: "timestampz"}), do: timestamp()

  def match(%{type: "varchar", name: name, options: options}) do
    if String.ends_with?(to_string(name), "_id") do
      varchar(options)
    else
      readable_varchar(options)
    end
  end

  def transform(%{ecto_type: :utc_datetime_usec}, value), do: DateTime.add(value, 0, :microsecond)
  def transform(%{ecto_type: :utc_datetime}, value), do: DateTime.truncate(value, :second)

  def transform(_, value) do
    value
  end

  # def transform(_, value), do: value

  defp readable_varchar(options) do
    max_size = options[:size] || 255

    String.slice(Lorem.sentence(max_size), 1..max_size)
  end

  defp varchar(options) do
    max_size = options[:size] || 255

    size = Enum.random(1..max_size)
    to_string(Lorem.characters(size))
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
