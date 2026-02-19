defmodule ExWxf.VarintTest do
  use ExUnit.Case, async: true
  use ExUnitProperties

  alias ExWxf.Varint

  describe "encode/1" do
    test "encodes 0" do
      assert Varint.encode(0) == <<0x00>>
    end

    test "encodes single-byte values (0-127)" do
      assert Varint.encode(1) == <<0x01>>
      assert Varint.encode(127) == <<0x7F>>
    end

    test "encodes two-byte values (128-16383)" do
      assert Varint.encode(128) == <<0x80, 0x01>>
      assert Varint.encode(300) == <<0xAC, 0x02>>
    end

    test "encodes three-byte values" do
      assert Varint.encode(16_384) == <<0x80, 0x80, 0x01>>
    end

    test "encodes large values" do
      assert Varint.encode(268_435_455) == <<0xFF, 0xFF, 0xFF, 0x7F>>
    end
  end

  describe "decode/1" do
    test "decodes 0" do
      assert Varint.decode(<<0x00, "rest">>) == {0, "rest"}
    end

    test "decodes single-byte values" do
      assert Varint.decode(<<0x01>>) == {1, <<>>}
      assert Varint.decode(<<0x7F>>) == {127, <<>>}
    end

    test "decodes two-byte values" do
      assert Varint.decode(<<0x80, 0x01>>) == {128, <<>>}
      assert Varint.decode(<<0xAC, 0x02>>) == {300, <<>>}
    end

    test "decodes and returns remaining bytes" do
      assert Varint.decode(<<0x01, 0xFF, 0xAA>>) == {1, <<0xFF, 0xAA>>}
    end

    test "raises on truncated input" do
      assert_raise ExWxf.DecodeError, fn ->
        Varint.decode(<<0x80>>)
      end
    end
  end

  describe "round-trip" do
    property "encode then decode returns original value" do
      check all value <- integer(0..1_000_000_000) do
        encoded = Varint.encode(value)
        assert {^value, <<>>} = Varint.decode(encoded)
      end
    end
  end
end
