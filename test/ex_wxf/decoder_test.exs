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
end
