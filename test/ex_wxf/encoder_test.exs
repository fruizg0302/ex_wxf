defmodule ExWxf.EncoderTest do
  use ExUnit.Case, async: true

  alias ExWxf.Encoder

  describe "encode_expression/1 — integers" do
    test "encodes integer 0 as Integer8" do
      assert Encoder.encode_expression(0) == <<0x43, 0>>
    end

    test "encodes positive integer8" do
      assert Encoder.encode_expression(42) == <<0x43, 42>>
    end

    test "encodes negative integer8" do
      assert Encoder.encode_expression(-1) == <<0x43, 255>>
    end

    test "encodes integer that needs 16 bits" do
      assert Encoder.encode_expression(200) == <<0x6A, 200, 0>>
    end

    test "encodes negative integer16" do
      assert Encoder.encode_expression(-200) == <<0x6A, 56, 0xFF>>
    end

    test "encodes integer that needs 32 bits" do
      assert Encoder.encode_expression(100_000) == <<0x69, 0xA0, 0x86, 0x01, 0x00>>
    end

    test "encodes integer that needs 64 bits" do
      val = 3_000_000_000
      <<a, b, c, d, e, f, g, h>> = <<val::64-little-signed>>
      assert Encoder.encode_expression(val) == <<0x4C, a, b, c, d, e, f, g, h>>
    end

    test "encodes big integer beyond 64-bit range" do
      big = 9_999_999_999_999_999_999_999
      digits = Integer.to_string(big)
      len_bytes = ExWxf.Varint.encode(byte_size(digits))
      assert Encoder.encode_expression(big) == <<0x49>> <> len_bytes <> digits
    end

    test "encodes negative big integer" do
      big = -9_999_999_999_999_999_999_999
      digits = Integer.to_string(big)
      len_bytes = ExWxf.Varint.encode(byte_size(digits))
      assert Encoder.encode_expression(big) == <<0x49>> <> len_bytes <> digits
    end
  end

  describe "encode_expression/1 — reals" do
    test "encodes float as Real64" do
      assert Encoder.encode_expression(3.14) == <<0x72, 3.14::64-little-float>>
    end

    test "encodes 0.0" do
      assert Encoder.encode_expression(0.0) == <<0x72, 0.0::64-little-float>>
    end
  end

  describe "encode_expression/1 — strings" do
    test "encodes empty string" do
      assert Encoder.encode_expression("") == <<0x53, 0x00>>
    end

    test "encodes ASCII string" do
      assert Encoder.encode_expression("hello") == <<0x53, 5, "hello">>
    end

    test "encodes UTF-8 string with multibyte chars" do
      str = "héllo"
      bytes = byte_size(str)
      len_bytes = ExWxf.Varint.encode(bytes)
      assert Encoder.encode_expression(str) == <<0x53>> <> len_bytes <> str
    end
  end

  describe "encode_expression/1 — symbols (atoms)" do
    test "encodes true as Symbol True" do
      assert Encoder.encode_expression(true) == <<0x73, 4, "True">>
    end

    test "encodes false as Symbol False" do
      assert Encoder.encode_expression(false) == <<0x73, 5, "False">>
    end

    test "encodes nil as Symbol Null" do
      assert Encoder.encode_expression(nil) == <<0x73, 4, "Null">>
    end

    test "encodes arbitrary atom as Symbol" do
      assert Encoder.encode_expression(:Plus) == <<0x73, 4, "Plus">>
    end
  end

  describe "encode_expression/1 — Expression.Symbol struct" do
    test "encodes Symbol struct" do
      sym = %ExWxf.Expression.Symbol{name: "Global`x"}
      name = "Global`x"
      assert Encoder.encode_expression(sym) == <<0x73, byte_size(name), name::binary>>
    end
  end

  describe "encode_expression/1 — Expression.BigReal struct" do
    test "encodes BigReal struct" do
      br = %ExWxf.Expression.BigReal{value: "3.14159265358979323846`30."}
      val = br.value
      len_bytes = ExWxf.Varint.encode(byte_size(val))
      assert Encoder.encode_expression(br) == <<0x52>> <> len_bytes <> val
    end
  end

  describe "encode_expression/1 — Expression.BinaryString struct" do
    test "encodes BinaryString struct" do
      bs = %ExWxf.Expression.BinaryString{data: <<0xFF, 0x00, 0xAA>>}
      assert Encoder.encode_expression(bs) == <<0x42, 3, 0xFF, 0x00, 0xAA>>
    end
  end

  describe "encode_expression/1 — lists" do
    test "encodes empty list" do
      result = Encoder.encode_expression([])
      # Function(0) + Symbol("List")
      assert result == <<0x66, 0x00, 0x73, 4, "List">>
    end

    test "encodes list of integers" do
      result = Encoder.encode_expression([1, 2, 3])

      assert result ==
               <<0x66, 3>> <>
                 <<0x73, 4, "List">> <> <<0x43, 1>> <> <<0x43, 2>> <> <<0x43, 3>>
    end

    test "encodes nested list" do
      result = Encoder.encode_expression([[1, 2], [3]])

      expected =
        <<0x66, 2>> <>
          <<0x73, 4, "List">> <>
          (<<0x66, 2>> <> <<0x73, 4, "List">> <> <<0x43, 1>> <> <<0x43, 2>>) <>
          <<0x66, 1>> <> <<0x73, 4, "List">> <> <<0x43, 3>>

      assert result == expected
    end
  end

  describe "encode_expression/1 — maps" do
    test "encodes empty map" do
      result = Encoder.encode_expression(%{})
      assert result == <<0x41, 0x00>>
    end

    test "encodes map with string keys" do
      result = Encoder.encode_expression(%{"a" => 1})
      # Association(1) Rule String("a") Integer8(1)
      assert result == <<0x41, 1, 0x2D>> <> <<0x53, 1, "a">> <> <<0x43, 1>>
    end
  end

  describe "encode_expression/1 — Function struct" do
    test "encodes Function with symbol head" do
      func = %ExWxf.Expression.Function{
        head: %ExWxf.Expression.Symbol{name: "Plus"},
        parts: [1, 2]
      }

      result = Encoder.encode_expression(func)
      assert result == <<0x66, 2>> <> <<0x73, 4, "Plus">> <> <<0x43, 1>> <> <<0x43, 2>>
    end
  end

  describe "encode_expression/1 — Association struct" do
    test "encodes Association with rules" do
      assoc = %ExWxf.Expression.Association{
        rules: [
          %ExWxf.Expression.Rule{key: "x", value: 1},
          %ExWxf.Expression.Rule{key: "y", value: 2, delayed: true}
        ]
      }

      result = Encoder.encode_expression(assoc)

      expected =
        <<0x41, 2>> <>
          <<0x2D>> <>
          <<0x53, 1, "x">> <>
          <<0x43, 1>> <>
          <<0x3A>> <> <<0x53, 1, "y">> <> <<0x43, 2>>

      assert result == expected
    end
  end

  describe "encode_expression/1 — PackedArray" do
    test "encodes 1D integer32 packed array" do
      data = <<1::32-little-signed, 2::32-little-signed, 3::32-little-signed>>

      arr = %ExWxf.Expression.PackedArray{
        type: :integer32,
        dimensions: [3],
        data: data
      }

      result = Encoder.encode_expression(arr)
      # PackedArray + type_byte(0x02) + rank_varint(1) + dim_varint(3) + data
      expected = <<0xC1, 0x02>> <> ExWxf.Varint.encode(1) <> ExWxf.Varint.encode(3) <> data
      assert result == expected
    end

    test "encodes 2D real64 packed array" do
      data =
        <<1.0::64-little-float, 2.0::64-little-float, 3.0::64-little-float, 4.0::64-little-float>>

      arr = %ExWxf.Expression.PackedArray{
        type: :real64,
        dimensions: [2, 2],
        data: data
      }

      result = Encoder.encode_expression(arr)

      expected =
        <<0xC1, 0x23>> <>
          ExWxf.Varint.encode(2) <>
          ExWxf.Varint.encode(2) <> ExWxf.Varint.encode(2) <> data

      assert result == expected
    end
  end

  describe "encode_expression/1 — NumericArray" do
    test "encodes unsigned_integer8 numeric array" do
      data = <<10, 20, 30>>

      arr = %ExWxf.Expression.NumericArray{
        type: :unsigned_integer8,
        dimensions: [3],
        data: data
      }

      result = Encoder.encode_expression(arr)
      expected = <<0xC2, 0x10>> <> ExWxf.Varint.encode(1) <> ExWxf.Varint.encode(3) <> data
      assert result == expected
    end
  end
end
