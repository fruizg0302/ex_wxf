defmodule ExWxf.Encoder do
  @moduledoc "Encodes Elixir terms into WXF binary expression data (no header)."

  alias ExWxf.{Tokens, Varint}
  alias ExWxf.Expression

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

  defp encode_symbol_name(name) do
    <<Tokens.symbol()>> <> Varint.encode(byte_size(name)) <> name
  end
end
