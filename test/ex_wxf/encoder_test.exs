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
end
