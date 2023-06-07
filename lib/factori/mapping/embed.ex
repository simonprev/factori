defmodule Factori.Mapping.Embed do
  @behaviour Factori.Mapping

  def match(%{struct_embed: {:one, embed_schema, columns}}) do
    {:map, embed_schema, columns}
  end

  def match(%{struct_embed: {:many, embed_schema, columns}}) do
    {:list, embed_schema, columns}
  end
end
