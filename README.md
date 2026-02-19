# ExWxf

Elixir encoder/decoder for the [Wolfram eXchange Format (WXF)](https://reference.wolfram.com/language/tutorial/WXFFormatDescription.html), a binary serialization format for Wolfram Language expressions.

## Installation

Add `ex_wxf` to your `mix.exs`:

    {:ex_wxf, "~> 0.1"}

## Usage

    # Encode Elixir terms to WXF binary
    binary = ExWxf.encode!([1, "hello", %{"key" => 3.14}])

    # Decode WXF binary back to Elixir terms
    ExWxf.decode!(binary)
    #=> [1, "hello", %{"key" => 3.14}]

    # With compression
    ExWxf.encode!(data, compress: true)

    # Raw mode (preserves Expression structs)
    ExWxf.decode!(binary, raw: true)

## Supported Types

| WXF Type | Elixir Encoding | Elixir Decoding |
|----------|----------------|-----------------|
| Integer8/16/32/64 | `integer` | `integer` |
| BigInteger | `integer` (> 64-bit) | `integer` |
| Real64 | `float` | `float` |
| String | `binary` | `binary` |
| Symbol | `atom` / `Expression.Symbol` | `true`/`false`/`nil` or `Expression.Symbol` |
| Function (List head) | `list` | `list` |
| Function (other head) | `Expression.Function` | `Expression.Function` |
| Association | `map` | `map` |
| PackedArray | `Expression.PackedArray` | `Expression.PackedArray` |
| NumericArray | `Expression.NumericArray` | `Expression.NumericArray` |
| BigReal | `Expression.BigReal` | `Expression.BigReal` |
| BinaryString | `Expression.BinaryString` | `Expression.BinaryString` |

## License

MIT
