defmodule ExWxfTest do
  use ExUnit.Case, async: true
  use ExUnitProperties

  describe "encode!/2 and decode!/2 — round-trip" do
    test "integer" do
      assert ExWxf.decode!(ExWxf.encode!(42)) == 42
    end

    test "negative integer" do
      assert ExWxf.decode!(ExWxf.encode!(-100)) == -100
    end

    test "big integer" do
      big = 9_999_999_999_999_999_999_999
      assert ExWxf.decode!(ExWxf.encode!(big)) == big
    end

    test "float" do
      assert ExWxf.decode!(ExWxf.encode!(3.14)) == 3.14
    end

    test "string" do
      assert ExWxf.decode!(ExWxf.encode!("hello world")) == "hello world"
    end

    test "empty string" do
      assert ExWxf.decode!(ExWxf.encode!("")) == ""
    end

    test "true/false/nil" do
      assert ExWxf.decode!(ExWxf.encode!(true)) == true
      assert ExWxf.decode!(ExWxf.encode!(false)) == false
      assert ExWxf.decode!(ExWxf.encode!(nil)) == nil
    end

    test "list of integers" do
      assert ExWxf.decode!(ExWxf.encode!([1, 2, 3])) == [1, 2, 3]
    end

    test "nested list" do
      assert ExWxf.decode!(ExWxf.encode!([[1, 2], [3]])) == [[1, 2], [3]]
    end

    test "empty list" do
      assert ExWxf.decode!(ExWxf.encode!([])) == []
    end

    test "map with string keys" do
      map = %{"a" => 1, "b" => "hello"}
      assert ExWxf.decode!(ExWxf.encode!(map)) == map
    end

    test "empty map" do
      assert ExWxf.decode!(ExWxf.encode!(%{})) == %{}
    end

    test "mixed nested structure" do
      data = [1, "two", 3.0, [4, 5], %{"nested" => true}]
      assert ExWxf.decode!(ExWxf.encode!(data)) == data
    end
  end

  describe "encode/2 and decode/2 — ok/error tuples" do
    test "encode returns ok tuple" do
      assert {:ok, binary} = ExWxf.encode(42)
      assert is_binary(binary)
    end

    test "decode returns ok tuple" do
      {:ok, binary} = ExWxf.encode(42)
      assert {:ok, 42} = ExWxf.decode(binary)
    end

    test "decode returns error for invalid binary" do
      assert {:error, %ExWxf.DecodeError{}} = ExWxf.decode(<<0x00, 0x00>>)
    end
  end

  describe "header" do
    test "encode produces WXF header" do
      binary = ExWxf.encode!(42)
      assert <<"8:", _rest::binary>> = binary
    end

    test "decode rejects missing header" do
      assert {:error, %ExWxf.DecodeError{}} = ExWxf.decode(<<0x43, 42>>)
    end
  end

  describe "compression" do
    test "encode with compress: true produces compressed header" do
      binary = ExWxf.encode!(42, compress: true)
      assert <<"8C:", _rest::binary>> = binary
    end

    test "round-trip with compression" do
      data = List.duplicate("hello", 100)
      compressed = ExWxf.encode!(data, compress: true)
      uncompressed = ExWxf.encode!(data)
      assert ExWxf.decode!(compressed) == data
      assert byte_size(compressed) < byte_size(uncompressed)
    end
  end

  describe "raw mode" do
    test "raw: true preserves Symbol structs" do
      binary = ExWxf.encode!(true)
      result = ExWxf.decode!(binary, raw: true)
      assert result == %ExWxf.Expression.Symbol{name: "True"}
    end

    test "raw: true preserves Function struct for lists" do
      binary = ExWxf.encode!([1, 2])
      result = ExWxf.decode!(binary, raw: true)
      assert %ExWxf.Expression.Function{head: %ExWxf.Expression.Symbol{name: "List"}} = result
    end

    test "raw: true preserves Association struct for maps" do
      binary = ExWxf.encode!(%{"a" => 1})
      result = ExWxf.decode!(binary, raw: true)
      assert %ExWxf.Expression.Association{} = result
    end
  end

  describe "property-based round-trip" do
    property "integers round-trip" do
      check all int <- integer() do
        assert ExWxf.decode!(ExWxf.encode!(int)) == int
      end
    end

    property "floats round-trip" do
      check all f <- float() do
        result = ExWxf.decode!(ExWxf.encode!(f))
        assert result == f or Float.to_string(result) == Float.to_string(f)
      end
    end

    property "strings round-trip" do
      check all s <- string(:printable) do
        assert ExWxf.decode!(ExWxf.encode!(s)) == s
      end
    end

    property "lists of integers round-trip" do
      check all list <- list_of(integer(), max_length: 20) do
        assert ExWxf.decode!(ExWxf.encode!(list)) == list
      end
    end
  end
end
