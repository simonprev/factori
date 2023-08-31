defmodule Factori.Mapping.Embed do
  @behaviour Factori.Mapping

  def match(%{struct_embed: {:one, embed_schema, columns}}) do
    {:map, embed_schema, columns}
  end

  def match(%{struct_embed: {:many, embed_schema, columns}}) do
    {:list, embed_schema, columns}
  end

  def transform(%{struct_embed: {_, struct_embed, _}}, value) do
    cond do
      is_struct(value, struct_embed) ->
        value

      is_list(value) ->
        Enum.map(value, fn item ->
          if is_struct(item, struct_embed), do: item, else: struct!(item, struct_embed)
        end)

      is_map(value) ->
        struct!(struct_embed, value)
    end
  end

  def transform(_, value), do: value
end
