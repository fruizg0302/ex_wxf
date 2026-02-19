defmodule ExWxf.ReferenceTest do
  use ExUnit.Case, async: true

  @fixtures_dir Path.join([__DIR__, "..", "fixtures"]) |> Path.expand()

  defp read_fixture(name) do
    Path.join(@fixtures_dir, name) |> File.read!()
  end

  describe "decodes Wolfram-generated WXF binaries" do
    test "integer 42" do
      assert ExWxf.decode!(read_fixture("integer42.wxf")) == 42
    end

    test "string hello" do
      assert ExWxf.decode!(read_fixture("string_hello.wxf")) == "hello"
    end

    test "list {1, 2, 3}" do
      assert ExWxf.decode!(read_fixture("list_123.wxf")) == [1, 2, 3]
    end

    test "association" do
      result = ExWxf.decode!(read_fixture("assoc.wxf"))
      assert result == %{"a" => 1, "b" => "hello"}
    end

    test "nested structure" do
      result = ExWxf.decode!(read_fixture("nested.wxf"))
      assert result == [1, "two", 3.0, [4, 5]]
    end

    test "big integer" do
      assert ExWxf.decode!(read_fixture("big_integer.wxf")) == 99_999_999_999_999_999_999
    end

    test "real pi" do
      result = ExWxf.decode!(read_fixture("real_pi.wxf"))
      assert_in_delta result, 3.141592653589793, 1.0e-15
    end

    test "True" do
      assert ExWxf.decode!(read_fixture("true.wxf")) == true
    end

    test "Null" do
      assert ExWxf.decode!(read_fixture("null.wxf")) == nil
    end

    test "empty list" do
      assert ExWxf.decode!(read_fixture("empty_list.wxf")) == []
    end
  end
end
