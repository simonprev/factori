defmodule Factori.Mapping.Faker do
  @behaviour Factori.Mapping

  @ranges %{
    smallint: -32768..32767,
    integer: -2_147_483_648..2_147_483_647,
    serial: 1..2_147_483_647,
    bigserial: 1..9_223_372_036_854_775_807
  }

  def match(%{type: "uuid"}), do: Ecto.UUID.generate()
  def match(%{type: "json"}), do: "{}"
  def match(%{type: "jsonb"}), do: "{}"
  def match(%{type: "int2"}), do: Enum.random(@ranges.smallint)
  def match(%{type: "int4"}), do: Enum.random(@ranges.integer)
  def match(%{type: "int8"}), do: Enum.random(@ranges.bigserial)
  def match(%{type: "float4"}), do: Enum.random(@ranges.serial)
  def match(%{type: "float8"}), do: Enum.random(@ranges.bigserial)
  def match(%{type: "text"}), do: Faker.Lorem.paragraph(5)
  def match(%{type: "bool"}), do: Enum.random([true, false])
  def match(%{type: "time"}), do: time()
  def match(%{type: "date"}), do: date()
  def match(%{type: "timestamp"}), do: timestamp()
  def match(%{type: "timestampz"}), do: timestamp()
  def match(%{type: "char", options: options}), do: varchar(options)

  def match(%{type: "varchar", name: name, options: options}) do
    if String.ends_with?(to_string(name), "_id") do
      varchar(options)
    else
      readable_varchar(options)
    end
  end

  defp readable_varchar(options) do
    max_size = options[:size] || 255

    String.slice(Faker.Lorem.sentence(max_size), 1..max_size)
  end

  defp varchar(options) do
    max_size = options[:size] || 255

    size = Enum.random(1..max_size)
    to_string(Faker.Lorem.characters(size))
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
