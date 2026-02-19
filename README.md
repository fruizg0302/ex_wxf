# ExWxf

Elixir encoder/decoder for the [Wolfram eXchange Format (WXF)](https://reference.wolfram.com/language/tutorial/WXFFormatDescription.html), a compact binary serialization format for Wolfram Language expressions.

ExWxf lets you move data between Elixir and the Wolfram ecosystem (Mathematica, Wolfram Engine, Wolfram Cloud) without going through slow text-based formats like JSON or MathML.

## Installation

Add `ex_wxf` to your `mix.exs`:

```elixir
def deps do
  [
    {:ex_wxf, "~> 0.1"}
  ]
end
```

## Quick Start

```elixir
# Encode Elixir terms to WXF binary
binary = ExWxf.encode!([1, "hello", %{"key" => 3.14}])

# Decode WXF binary back to Elixir terms
ExWxf.decode!(binary)
#=> [1, "hello", %{"key" => 3.14}]
```

## Use Cases

### Exchanging Data with Wolfram Engine / Mathematica

Send structured data from Elixir to a Wolfram Engine process via WXF, and parse results back. WXF is the native binary wire format Wolfram uses internally, making it the fastest option for interprocess communication.

```elixir
# Prepare a dataset for Wolfram computation
dataset = %{
  "values" => [1.5, 2.7, 3.9, 4.1, 5.6],
  "labels" => ["a", "b", "c", "d", "e"]
}

binary = ExWxf.encode!(dataset)
# => Send binary to Wolfram Engine via port/stdin

# Parse Wolfram Engine response
result = ExWxf.decode!(response_binary)
```

### Compact Binary Serialization

WXF is significantly more compact than JSON for numeric-heavy data. Combined with built-in zlib compression, it works well for storage and network transfer.

```elixir
data = Enum.to_list(1..1000)

# Uncompressed
binary = ExWxf.encode!(data)

# Compressed — ideal for large payloads
compressed = ExWxf.encode!(data, compress: true)
byte_size(compressed) < byte_size(binary)
#=> true

# Decoding handles both transparently
ExWxf.decode!(compressed) == data
#=> true
```

### Working with Wolfram Language Expressions

When you need to represent Wolfram expressions that don't have a direct Elixir equivalent (symbolic math, custom function heads), use the Expression structs.

```elixir
alias ExWxf.Expression.{Symbol, Function}

# Represent Wolfram expression: Plus[1, Times[2, 3]]
expr = %Function{
  head: %Symbol{name: "Plus"},
  parts: [
    1,
    %Function{
      head: %Symbol{name: "Times"},
      parts: [2, 3]
    }
  ]
}

binary = ExWxf.encode!(expr)
```

### Preserving Full Expression Structure with Raw Mode

By default, decoding maps Wolfram types to native Elixir types (`List[...]` becomes a list, `Association[...]` becomes a map, `Symbol["True"]` becomes `true`). Use `raw: true` to preserve the original Wolfram structure.

```elixir
binary = ExWxf.encode!([1, 2, 3])

# Default — auto-mapped to native types
ExWxf.decode!(binary)
#=> [1, 2, 3]

# Raw — preserves Expression structs
ExWxf.decode!(binary, raw: true)
#=> %ExWxf.Expression.Function{
#     head: %ExWxf.Expression.Symbol{name: "List"},
#     parts: [1, 2, 3]
#   }
```

This is useful when you need to inspect or transform the expression tree before converting to Elixir types, or when the Wolfram expression has semantics that auto-mapping would lose (e.g., `RuleDelayed` vs `Rule`).

### Associations with Delayed Rules

Wolfram associations distinguish between immediate rules (`->`) and delayed rules (`:>`). ExWxf preserves this in raw mode.

```elixir
alias ExWxf.Expression.{Association, Rule}

assoc = %Association{
  rules: [
    %Rule{key: "x", value: 1, delayed: false},
    %Rule{key: "y", value: 2, delayed: true}
  ]
}

binary = ExWxf.encode!(assoc)

# Auto-mapped decoding (delayed info is lost)
ExWxf.decode!(binary)
#=> %{"x" => 1, "y" => 2}

# Raw decoding preserves the distinction
ExWxf.decode!(binary, raw: true)
#=> %ExWxf.Expression.Association{rules: [
#     %ExWxf.Expression.Rule{key: "x", value: 1, delayed: false},
#     %ExWxf.Expression.Rule{key: "y", value: 2, delayed: true}
#   ]}
```

### Numeric Arrays for Scientific Data

PackedArrays and NumericArrays encode dense, homogeneous numeric data efficiently — no per-element overhead. Use these for matrices, time series, image data, or any bulk numeric payload.

```elixir
alias ExWxf.Expression.PackedArray

# A 2x3 matrix of 64-bit floats
data = <<
  1.0::64-little-float, 2.0::64-little-float, 3.0::64-little-float,
  4.0::64-little-float, 5.0::64-little-float, 6.0::64-little-float
>>

array = %PackedArray{
  type: :real64,
  dimensions: [2, 3],
  data: data
}

binary = ExWxf.encode!(array)
{result, <<>>} = ExWxf.Decoder.decode_expression(binary)
result.dimensions
#=> [2, 3]
```

NumericArray supports the full set of types including unsigned integers:

```elixir
alias ExWxf.Expression.NumericArray

# Unsigned 8-bit pixel data (e.g., grayscale image row)
pixels = <<128, 255, 0, 64, 192>>

array = %NumericArray{
  type: :unsigned_integer8,
  dimensions: [5],
  data: pixels
}

ExWxf.encode!(array)
```

**Supported array types:** `:integer8`, `:integer16`, `:integer32`, `:integer64`, `:unsigned_integer8`, `:unsigned_integer16`, `:unsigned_integer32`, `:unsigned_integer64`, `:real32`, `:real64`, `:complex_real32`, `:complex_real64`

### Arbitrary-Precision Numbers

BigReal values preserve Wolfram's `InputForm` precision notation, which carries precision metadata that IEEE 754 floats cannot represent.

```elixir
alias ExWxf.Expression.BigReal

big = %BigReal{value: "3.14159265358979323846`30."}
binary = ExWxf.encode!(big)

ExWxf.decode!(binary)
#=> %ExWxf.Expression.BigReal{value: "3.14159265358979323846`30."}
```

Big integers beyond 64-bit range are handled automatically:

```elixir
big = 9_999_999_999_999_999_999_999
binary = ExWxf.encode!(big)
ExWxf.decode!(binary)
#=> 9999999999999999999999
```

### Raw Binary Data

BinaryString wraps opaque byte sequences (Wolfram `ByteArray`):

```elixir
alias ExWxf.Expression.BinaryString

bs = %BinaryString{data: <<0xFF, 0x00, 0xAA, 0x55>>}
binary = ExWxf.encode!(bs)

ExWxf.decode!(binary)
#=> %ExWxf.Expression.BinaryString{data: <<255, 0, 170, 85>>}
```

### Error Handling

Both tuple-returning and bang variants are provided:

```elixir
# Bang variants raise on error
ExWxf.encode!(self())
#=> ** (ExWxf.EncodeError) unsupported term: #PID<0.123.0>

ExWxf.decode!(<<0xFF>>)
#=> ** (ExWxf.DecodeError) invalid WXF header: expected "8:" or "8C:"

# Tuple variants return {:ok, _} or {:error, _}
{:error, %ExWxf.EncodeError{}} = ExWxf.encode(self())
{:error, %ExWxf.DecodeError{}} = ExWxf.decode(<<0xFF>>)
```

## API Reference

### Encoding

| Function | Returns | Description |
|----------|---------|-------------|
| `ExWxf.encode(term, opts)` | `{:ok, binary}` or `{:error, EncodeError}` | Encode with error tuple |
| `ExWxf.encode!(term, opts)` | `binary` | Encode or raise |

**Options:** `compress: true` — apply zlib compression to the WXF body.

### Decoding

| Function | Returns | Description |
|----------|---------|-------------|
| `ExWxf.decode(binary, opts)` | `{:ok, term}` or `{:error, DecodeError}` | Decode with error tuple |
| `ExWxf.decode!(binary, opts)` | `term` | Decode or raise |

**Options:** `raw: true` — return Expression structs instead of auto-mapping to native Elixir types.

## Type Mapping

### Encoding (Elixir to WXF)

| Elixir Type | WXF Type |
|-------------|----------|
| `integer` (fits 8/16/32/64 bits) | Integer8/16/32/64 |
| `integer` (beyond 64-bit) | BigInteger |
| `float` | Real64 |
| `binary` (string) | String |
| `true` / `false` / `nil` | Symbol (`True` / `False` / `Null`) |
| `atom` | Symbol |
| `list` | Function with `List` head |
| `map` | Association with Rules |
| `%Expression.Symbol{}` | Symbol |
| `%Expression.Function{}` | Function |
| `%Expression.Association{}` | Association |
| `%Expression.Rule{}` | Rule / RuleDelayed |
| `%Expression.BigReal{}` | BigReal |
| `%Expression.BinaryString{}` | BinaryString |
| `%Expression.PackedArray{}` | PackedArray |
| `%Expression.NumericArray{}` | NumericArray |

### Decoding (WXF to Elixir)

| WXF Type | Default Decoding | Raw Decoding |
|----------|-----------------|--------------|
| Integer8/16/32/64 | `integer` | `integer` |
| BigInteger | `integer` | `integer` |
| Real64 | `float` | `float` |
| String | `binary` | `binary` |
| Symbol `True`/`False`/`Null` | `true`/`false`/`nil` | `%Expression.Symbol{}` |
| Symbol (other) | `%Expression.Symbol{}` | `%Expression.Symbol{}` |
| Function with `List` head | `list` | `%Expression.Function{}` |
| Function (other head) | `%Expression.Function{}` | `%Expression.Function{}` |
| Association | `map` | `%Expression.Association{}` |
| BigReal | `%Expression.BigReal{}` | `%Expression.BigReal{}` |
| BinaryString | `%Expression.BinaryString{}` | `%Expression.BinaryString{}` |
| PackedArray | `%Expression.PackedArray{}` | `%Expression.PackedArray{}` |
| NumericArray | `%Expression.NumericArray{}` | `%Expression.NumericArray{}` |

## Development

```bash
# Run tests
mix test

# Pre-commit checks (compile, format, credo, test)
mix precommit

# Full quality gate (credo strict, dialyzer, sobelow, 97% coverage)
mix quality
```

## License

MIT
