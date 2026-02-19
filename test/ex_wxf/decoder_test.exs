defmodule ExWxf.DecoderTest do
  use ExUnit.Case, async: true

  alias ExWxf.Decoder

  describe "decode_expression/1 — integers" do
    test "decodes Integer8" do
      assert Decoder.decode_expression(<<0x43, 42>>) == {42, <<>>}
    end

    test "decodes negative Integer8" do
      assert Decoder.decode_expression(<<0x43, 255>>) == {-1, <<>>}
    end

    test "decodes Integer16" do
      assert Decoder.decode_expression(<<0x6A, 200, 0>>) == {200, <<>>}
    end

    test "decodes Integer32" do
      assert Decoder.decode_expression(<<0x69, 0xA0, 0x86, 0x01, 0x00>>) == {100_000, <<>>}
    end

    test "decodes Integer64" do
      val = 3_000_000_000
      input = <<0x4C, val::64-little-signed>>
      assert Decoder.decode_expression(input) == {val, <<>>}
    end

    test "decodes BigInteger" do
      digits = "9999999999999999999999"
      len_bytes = ExWxf.Varint.encode(byte_size(digits))
      input = <<0x49>> <> len_bytes <> digits
      assert Decoder.decode_expression(input) == {9_999_999_999_999_999_999_999, <<>>}
    end

    test "decodes negative BigInteger" do
      digits = "-9999999999999999999999"
      len_bytes = ExWxf.Varint.encode(byte_size(digits))
      input = <<0x49>> <> len_bytes <> digits
      assert Decoder.decode_expression(input) == {-9_999_999_999_999_999_999_999, <<>>}
    end
  end

  describe "decode_expression/1 — reals" do
    test "decodes Real64" do
      input = <<0x72, 3.14::64-little-float>>
      assert Decoder.decode_expression(input) == {3.14, <<>>}
    end
  end

  describe "decode_expression/1 — strings" do
    test "decodes empty string" do
      assert Decoder.decode_expression(<<0x53, 0x00>>) == {"", <<>>}
    end

    test "decodes ASCII string" do
      assert Decoder.decode_expression(<<0x53, 5, "hello">>) == {"hello", <<>>}
    end

    test "decodes and returns remaining bytes" do
      assert Decoder.decode_expression(<<0x53, 2, "hi", 0xFF>>) == {"hi", <<0xFF>>}
    end
  end

  describe "decode_expression/1 — symbols" do
    test "decodes Symbol and auto-maps True" do
      assert Decoder.decode_expression(<<0x73, 4, "True">>) == {true, <<>>}
    end

    test "decodes Symbol and auto-maps False" do
      assert Decoder.decode_expression(<<0x73, 5, "False">>) == {false, <<>>}
    end

    test "decodes Symbol and auto-maps Null" do
      assert Decoder.decode_expression(<<0x73, 4, "Null">>) == {nil, <<>>}
    end

    test "decodes other Symbol as struct" do
      {result, <<>>} = Decoder.decode_expression(<<0x73, 4, "Plus">>)
      assert result == %ExWxf.Expression.Symbol{name: "Plus"}
    end
  end

  describe "decode_expression/1 — BigReal" do
    test "decodes BigReal as struct" do
      val = "3.14`30."
      len_bytes = ExWxf.Varint.encode(byte_size(val))
      input = <<0x52>> <> len_bytes <> val
      {result, <<>>} = Decoder.decode_expression(input)
      assert result == %ExWxf.Expression.BigReal{value: val}
    end
  end

  describe "decode_expression/1 — BinaryString" do
    test "decodes BinaryString as struct" do
      input = <<0x42, 3, 0xFF, 0x00, 0xAA>>
      {result, <<>>} = Decoder.decode_expression(input)
      assert result == %ExWxf.Expression.BinaryString{data: <<0xFF, 0x00, 0xAA>>}
    end
  end

  describe "errors" do
    test "raises on unknown token" do
      assert_raise ExWxf.DecodeError, fn ->
        Decoder.decode_expression(<<0xFF>>)
      end
    end

    test "raises on empty input" do
      assert_raise ExWxf.DecodeError, fn ->
        Decoder.decode_expression(<<>>)
      end
    end
  end

  describe "decode_expression/1 — functions/lists" do
    test "decodes empty List" do
      input = <<0x66, 0x00, 0x73, 4, "List">>
      assert Decoder.decode_expression(input) == {[], <<>>}
    end

    test "decodes List of integers" do
      input = <<0x66, 3, 0x73, 4, "List", 0x43, 1, 0x43, 2, 0x43, 3>>
      assert Decoder.decode_expression(input) == {[1, 2, 3], <<>>}
    end

    test "decodes nested List" do
      input =
        <<0x66, 2, 0x73, 4, "List">> <>
          <<0x66, 2, 0x73, 4, "List", 0x43, 1, 0x43, 2>> <>
          <<0x66, 1, 0x73, 4, "List", 0x43, 3>>

      assert Decoder.decode_expression(input) == {[[1, 2], [3]], <<>>}
    end

    test "decodes non-List Function as struct" do
      input = <<0x66, 2, 0x73, 4, "Plus", 0x43, 1, 0x43, 2>>
      {result, <<>>} = Decoder.decode_expression(input)

      assert result == %ExWxf.Expression.Function{
               head: %ExWxf.Expression.Symbol{name: "Plus"},
               parts: [1, 2]
             }
    end
  end

  describe "decode_expression/1 — associations" do
    test "decodes empty Association" do
      input = <<0x41, 0x00>>
      assert Decoder.decode_expression(input) == {%{}, <<>>}
    end

    test "decodes Association with string keys" do
      input = <<0x41, 1, 0x2D, 0x53, 1, "a", 0x43, 1>>
      assert Decoder.decode_expression(input) == {%{"a" => 1}, <<>>}
    end

    test "decodes Association with multiple rules" do
      input = <<0x41, 2, 0x2D, 0x53, 1, "a", 0x43, 1, 0x2D, 0x53, 1, "b", 0x43, 2>>
      assert Decoder.decode_expression(input) == {%{"a" => 1, "b" => 2}, <<>>}
    end

    test "decodes Association with RuleDelayed" do
      input = <<0x41, 1, 0x3A, 0x53, 1, "x", 0x43, 5>>
      # Auto-mapped to plain map (delayed info lost in auto-mapping)
      assert Decoder.decode_expression(input) == {%{"x" => 5}, <<>>}
    end
  end

  describe "decode_expression/1 — PackedArray" do
    test "decodes 1D integer32 packed array" do
      data = <<1::32-little-signed, 2::32-little-signed, 3::32-little-signed>>
      input = <<0xC1, 0x02>> <> ExWxf.Varint.encode(1) <> ExWxf.Varint.encode(3) <> data

      {result, <<>>} = Decoder.decode_expression(input)

      assert result == %ExWxf.Expression.PackedArray{
               type: :integer32,
               dimensions: [3],
               data: data
             }
    end

    test "decodes 2D real64 packed array" do
      data =
        <<1.0::64-little-float, 2.0::64-little-float, 3.0::64-little-float,
          4.0::64-little-float>>

      input =
        <<0xC1, 0x23>> <>
          ExWxf.Varint.encode(2) <>
          ExWxf.Varint.encode(2) <> ExWxf.Varint.encode(2) <> data

      {result, <<>>} = Decoder.decode_expression(input)

      assert result == %ExWxf.Expression.PackedArray{
               type: :real64,
               dimensions: [2, 2],
               data: data
             }
    end
  end

  describe "decode_expression/1 — NumericArray" do
    test "decodes unsigned_integer8 numeric array" do
      data = <<10, 20, 30>>
      input = <<0xC2, 0x10>> <> ExWxf.Varint.encode(1) <> ExWxf.Varint.encode(3) <> data

      {result, <<>>} = Decoder.decode_expression(input)

      assert result == %ExWxf.Expression.NumericArray{
               type: :unsigned_integer8,
               dimensions: [3],
               data: data
             }
    end
  end
end
