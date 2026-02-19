defmodule ExWxf do
  @moduledoc """
  Elixir encoder/decoder for the Wolfram eXchange Format (WXF).

  WXF is a binary serialization format for Wolfram Language expressions.
  This library supports the full spec: integers, reals, strings, symbols,
  functions, associations, packed/numeric arrays, big integers/reals,
  and zlib compression.

  ## Quick Start

      iex> binary = ExWxf.encode!([1, "hello", %{"key" => 3.14}])
      iex> ExWxf.decode!(binary)
      [1, "hello", %{"key" => 3.14}]

  ## Options

  - `compress: true` — zlib-compress the body (encode only)
  - `raw: true` — skip auto-mapping, return Expression structs (decode only)
  """

  alias ExWxf.{Encoder, Decoder}

  @header_version "8"
  @header_compress "C"
  @header_separator ":"

  @spec encode(term(), keyword()) :: {:ok, binary()} | {:error, ExWxf.EncodeError.t()}
  def encode(term, opts \\ []) do
    {:ok, encode!(term, opts)}
  rescue
    e in ExWxf.EncodeError -> {:error, e}
  end

  @spec encode!(term(), keyword()) :: binary()
  def encode!(term, opts \\ []) do
    body = Encoder.encode_expression(term)
    compress = Keyword.get(opts, :compress, false)

    if compress do
      compressed = :zlib.compress(body)
      @header_version <> @header_compress <> @header_separator <> compressed
    else
      @header_version <> @header_separator <> body
    end
  end

  @spec decode(binary(), keyword()) :: {:ok, term()} | {:error, ExWxf.DecodeError.t()}
  def decode(binary, opts \\ []) do
    {:ok, decode!(binary, opts)}
  rescue
    e in ExWxf.DecodeError -> {:error, e}
  end

  @spec decode!(binary(), keyword()) :: term()
  def decode!(binary, opts \\ []) do
    raw = Keyword.get(opts, :raw, false)
    body = parse_header_and_decompress(binary)
    {result, _rest} = Decoder.decode_expression(body, raw: raw)
    result
  end

  defp parse_header_and_decompress(<<"8C:", compressed::binary>>) do
    :zlib.uncompress(compressed)
  end

  defp parse_header_and_decompress(<<"8:", body::binary>>) do
    body
  end

  defp parse_header_and_decompress(binary) do
    raise ExWxf.DecodeError,
      message: "invalid WXF header: expected \"8:\" or \"8C:\"",
      binary: binary
  end
end
