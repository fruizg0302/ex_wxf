defmodule ExWxf.ErrorTest do
  use ExUnit.Case, async: true

  test "EncodeError has correct fields" do
    error = ExWxf.EncodeError.exception(message: "test error", term: :foo)
    assert error.message == "test error"
    assert error.term == :foo
  end

  test "EncodeError has defaults" do
    error = ExWxf.EncodeError.exception([])
    assert error.message == "encoding failed"
    assert error.term == nil
  end

  test "DecodeError has correct fields" do
    error = ExWxf.DecodeError.exception(message: "bad data", binary: <<0xFF>>)
    assert error.message == "bad data"
    assert error.binary == <<0xFF>>
  end
end
