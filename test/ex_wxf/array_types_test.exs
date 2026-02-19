defmodule ExWxf.ArrayTypesTest do
  use ExUnit.Case, async: true

  alias ExWxf.ArrayTypes

  test "packed_type? returns true for packed types" do
    assert ArrayTypes.packed_type?(:integer32)
    assert ArrayTypes.packed_type?(:real64)
  end

  test "packed_type? returns false for non-packed types" do
    refute ArrayTypes.packed_type?(:unsigned_integer8)
  end

  test "round-trip to_byte/from_byte" do
    assert ArrayTypes.from_byte(ArrayTypes.to_byte(:complex_real64)) == :complex_real64
  end

  test "element_size returns correct sizes" do
    assert ArrayTypes.element_size(:integer8) == 1
    assert ArrayTypes.element_size(:complex_real64) == 16
  end
end
