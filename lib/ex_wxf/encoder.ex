defmodule ExWxf.Encoder do
  @moduledoc "Encodes Elixir terms into WXF binary expression data (no header)."

  alias ExWxf.Expression
  alias ExWxf.{Tokens, Varint}

  @spec encode_expression(term()) :: binary()
  def encode_expression(value) when is_integer(value) do
    encode_integer(value)
  end

  def encode_expression(value) when is_float(value) do
    <<Tokens.real64(), value::64-little-float>>
  end

  def encode_expression(value) when is_binary(value) do
    <<Tokens.string()>> <> Varint.encode(byte_size(value)) <> value
  end

  def encode_expression(true), do: encode_symbol_name("True")
  def encode_expression(false), do: encode_symbol_name("False")
  def encode_expression(nil), do: encode_symbol_name("Null")

  def encode_expression(%Expression.Symbol{name: name}) do
    encode_symbol_name(name)
  end

  def encode_expression(%Expression.BigReal{value: value}) do
    <<Tokens.big_real()>> <> Varint.encode(byte_size(value)) <> value
  end

  def encode_expression(%Expression.BinaryString{data: data}) do
    <<Tokens.binary_string()>> <> Varint.encode(byte_size(data)) <> data
  end

  def encode_expression(list) when is_list(list) do
    parts_binary = Enum.map_join(list, &encode_expression/1)

    <<Tokens.function()>> <>
      Varint.encode(length(list)) <> encode_symbol_name("List") <> parts_binary
  end

  def encode_expression(map) when is_map(map) and not is_struct(map) do
    rules_binary =
      map
      |> Enum.sort_by(fn {k, _v} -> k end)
      |> Enum.map_join(fn {key, value} ->
        <<Tokens.rule()>> <> encode_expression(key) <> encode_expression(value)
      end)

    <<Tokens.association()>> <> Varint.encode(map_size(map)) <> rules_binary
  end

  def encode_expression(%Expression.Function{head: head, parts: parts}) do
    parts_binary = Enum.map_join(parts, &encode_expression/1)

    <<Tokens.function()>> <>
      Varint.encode(length(parts)) <> encode_expression(head) <> parts_binary
  end

  def encode_expression(%Expression.Association{rules: rules}) do
    rules_binary = Enum.map_join(rules, &encode_rule/1)
    <<Tokens.association()>> <> Varint.encode(length(rules)) <> rules_binary
  end

  def encode_expression(%Expression.Rule{} = rule) do
    encode_rule(rule)
  end

  def encode_expression(%Expression.PackedArray{type: type, dimensions: dims, data: data}) do
    encode_array(Tokens.packed_array(), type, dims, data)
  end

  def encode_expression(%Expression.NumericArray{type: type, dimensions: dims, data: data}) do
    encode_array(Tokens.numeric_array(), type, dims, data)
  end

  def encode_expression(value) when is_atom(value) do
    encode_symbol_name(Atom.to_string(value))
  end

  defp encode_integer(value) when value >= -128 and value <= 127 do
    <<Tokens.integer8(), value::8-little-signed>>
  end

  defp encode_integer(value) when value >= -32_768 and value <= 32_767 do
    <<Tokens.integer16(), value::16-little-signed>>
  end

  defp encode_integer(value) when value >= -2_147_483_648 and value <= 2_147_483_647 do
    <<Tokens.integer32(), value::32-little-signed>>
  end

  defp encode_integer(value)
       when value >= -9_223_372_036_854_775_808 and value <= 9_223_372_036_854_775_807 do
    <<Tokens.integer64(), value::64-little-signed>>
  end

  defp encode_integer(value) do
    digits = Integer.to_string(value)
    <<Tokens.big_integer()>> <> Varint.encode(byte_size(digits)) <> digits
  end

  defp encode_array(token, type, dimensions, data) do
    type_byte = ExWxf.ArrayTypes.to_byte(type)
    rank = length(dimensions)
    dims_binary = Enum.map_join(dimensions, &Varint.encode/1)
    <<token, type_byte>> <> Varint.encode(rank) <> dims_binary <> data
  end

  defp encode_rule(%Expression.Rule{key: key, value: value, delayed: delayed}) do
    token = if delayed, do: Tokens.rule_delayed(), else: Tokens.rule()
    <<token>> <> encode_expression(key) <> encode_expression(value)
  end

  defp encode_symbol_name(name) do
    <<Tokens.symbol()>> <> Varint.encode(byte_size(name)) <> name
  end
end
