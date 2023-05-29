defmodule Factori.Variant do
  def insert(config, variant, variant_name, attrs, source_column) do
    case parse_arguments(variant, variant_name, attrs) do
      {:table_name, {table_name, attrs}} ->
        validate_table_attrs!(variant_name, table_name, attrs, config)
        Factori.insert(config, table_name, attrs, source_column)

      {:struct, {table_name, attrs, struct_module}} ->
        validate_struct_attrs!(struct_module, attrs)
        Factori.insert(config, table_name, struct_module, attrs, source_column)

      {:error, {:invalid_schema, struct_module}} ->
        raise Factori.InvalidSchemaError, schema: struct_module, name: variant_name

      {:error, :undefined_variant} ->
        raise Factori.UndefinedVariantError, name: variant_name, variants: config.variants
    end
  end

  def build(config, variant, variant_name, attrs, source_column) do
    case parse_arguments(variant, variant_name, attrs) do
      {:table_name, {table_name, attrs}} ->
        validate_table_attrs!(variant_name, table_name, attrs, config)
        Factori.build(config, table_name, attrs, source_column)

      {:struct, {table_name, attrs, struct_module}} ->
        validate_struct_attrs!(struct_module, attrs)
        Factori.build(config, table_name, struct_module, attrs, source_column)

      {:error, {:invalid_schema, struct_module}} ->
        raise Factori.InvalidSchemaError, schema: struct_module, name: variant_name

      {:error, :undefined_variant} ->
        raise Factori.UndefinedVariantError, name: variant_name, variants: config.variants
    end
  end

  def insert_list(config, variant, variant_name, count, attrs, source_column) do
    case parse_arguments(variant, variant_name, attrs) do
      {:table_name, {table_name, attrs}} ->
        validate_table_attrs!(variant_name, table_name, attrs, config)
        Factori.insert_list(config, table_name, count, attrs, source_column)

      {:struct, {table_name, attrs, struct_module}} ->
        validate_struct_attrs!(struct_module, attrs)
        Factori.insert_list(config, table_name, count, struct_module, attrs, source_column)

      {:error, {:invalid_schema, struct_module}} ->
        raise Factori.InvalidSchemaError, schema: struct_module, name: variant_name

      {:error, :undefined_variant} ->
        raise Factori.UndefinedVariantError, name: variant_name, variants: config.variants
    end
  end

  def seed(config, variant, variant_name, count, attrs, source_column) do
    case parse_arguments(variant, variant_name, attrs) do
      {:table_name, {table_name, attrs}} ->
        validate_table_attrs!(variant_name, table_name, attrs, config)
        Factori.seed(config, table_name, count, attrs, source_column, nil)

      {:struct, {table_name, attrs, struct_module}} ->
        validate_struct_attrs!(struct_module, attrs)
        Factori.seed(config, table_name, count, struct_module, attrs, source_column)

      {:error, {:invalid_schema, struct_module}} ->
        raise Factori.InvalidSchemaError, schema: struct_module, name: variant_name

      {:error, :undefined_variant} ->
        raise Factori.UndefinedVariantError, name: variant_name, variants: config.variants
    end
  end

  defp validate_table_attrs!(variant_name, table_name, attrs, config) do
    valid_attributes =
      table_name
      |> config.storage.get(config.storage_name)
      |> Enum.map(& &1.name)

    invalid_attrs =
      attrs
      |> List.wrap()
      |> Enum.reject(fn {key, _} -> key in valid_attributes end)
      |> Enum.map(fn {key, _} -> key end)

    if Enum.any?(invalid_attrs) do
      raise Factori.InvalidAttributeError, schema: variant_name, attributes: invalid_attrs
    end

    :ok
  end

  defp validate_struct_attrs!(struct_module, attrs) do
    invalid_attrs =
      attrs
      |> List.wrap()
      |> Enum.reject(fn {key, value} ->
        binded_struct = struct(struct_module, [{key, value}])
        Map.has_key?(binded_struct, key)
      end)
      |> Enum.map(fn {key, _} -> key end)

    if Enum.any?(invalid_attrs) do
      raise Factori.InvalidAttributeError, schema: struct_module, attributes: invalid_attrs
    end

    :ok
  end

  defp parse_arguments(variant, variant_name, attrs) do
    case variant do
      {_, table_name} when is_binary(table_name) ->
        {:table_name, {table_name, attrs}}

      {_, struct_module} when is_atom(struct_module) ->
        if table_name = struct_module_source!(struct_module) do
          {:struct, {table_name, attrs, struct_module}}
        else
          {:error, {:invalid_schema, struct_module}}
        end

      {_, table_name, variant_attrs} when is_binary(table_name) and is_list(variant_attrs) ->
        attrs = Keyword.merge(variant_attrs, attrs || [])
        {:table_name, {table_name, attrs}}

      {_, table_name, struct_module} when is_binary(table_name) and is_atom(struct_module) ->
        {:struct, {table_name, attrs, struct_module}}

      {_, struct_module, variant_attrs} when is_atom(struct_module) and is_list(variant_attrs) ->
        if table_name = struct_module_source!(struct_module) do
          attrs = Keyword.merge(variant_attrs, attrs || [])
          {:struct, {table_name, attrs, struct_module}}
        else
          {:error, {:invalid_schema, struct_module}}
        end

      {_, table_name, struct_module, variant_attrs}
      when is_binary(table_name) and is_atom(struct_module) and is_list(variant_attrs) ->
        attrs = Keyword.merge(variant_attrs, attrs || [])
        {:struct, {table_name, attrs, struct_module}}

      nil ->
        if variant_name && is_atom(variant_name) && function_exported?(variant_name, :__info__, 1) do
          parse_arguments({variant_name, variant_name}, variant_name, attrs)
        else
          {:error, :undefined_variant}
        end

      _ ->
        {:error, :undefined_variant}
    end
  end

  # To ensure that the schema is valid, we call the __schema__ instrospection function declared by Ecto.Schema
  # We can’t use reliably function_exported?/3 since the struct_module is sometimes not loaded yet.
  def struct_module_source!(struct_module) do
    struct_module.__schema__(:source)
  rescue
    UndefinedFunctionError -> nil
  end
end
