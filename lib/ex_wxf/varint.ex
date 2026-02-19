defmodule ExWxf.Varint do
  @moduledoc "LEB128 variable-length integer encoding/decoding for WXF."

  @spec encode(non_neg_integer()) :: binary()
  def encode(value) when is_integer(value) and value >= 0 do
    do_encode(value, <<>>)
  end

  @spec decode(binary()) :: {non_neg_integer(), binary()}
  def decode(binary) when is_binary(binary) do
    do_decode(binary, 0, 0)
  end

  defp do_encode(value, acc) when value < 128 do
    acc <> <<value::8>>
  end

  defp do_encode(value, acc) do
    byte = Bitwise.bor(Bitwise.band(value, 0x7F), 0x80)
    do_encode(Bitwise.bsr(value, 7), acc <> <<byte::8>>)
  end

  defp do_decode(<<byte::8, rest::binary>>, value, shift) do
    value = Bitwise.bor(value, Bitwise.bsl(Bitwise.band(byte, 0x7F), shift))

    if Bitwise.band(byte, 0x80) == 0 do
      {value, rest}
    else
      do_decode(rest, value, shift + 7)
    end
  end

  defp do_decode(<<>>, _value, _shift) do
    raise ExWxf.DecodeError, message: "truncated varint: unexpected end of input"
  end
end
