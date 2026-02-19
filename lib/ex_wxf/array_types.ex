defmodule ExWxf.ArrayTypes do
  @moduledoc "PackedArray and NumericArray value type byte constants and metadata."

  @type value_type ::
          :integer8
          | :integer16
          | :integer32
          | :integer64
          | :unsigned_integer8
          | :unsigned_integer16
          | :unsigned_integer32
          | :unsigned_integer64
          | :real32
          | :real64
          | :complex_real32
          | :complex_real64

  @type_to_byte %{
    integer8: 0x00,
    integer16: 0x01,
    integer32: 0x02,
    integer64: 0x03,
    unsigned_integer8: 0x10,
    unsigned_integer16: 0x11,
    unsigned_integer32: 0x12,
    unsigned_integer64: 0x13,
    real32: 0x22,
    real64: 0x23,
    complex_real32: 0x33,
    complex_real64: 0x34
  }

  @byte_to_type Map.new(@type_to_byte, fn {k, v} -> {v, k} end)

  @type_to_size %{
    integer8: 1,
    integer16: 2,
    integer32: 4,
    integer64: 8,
    unsigned_integer8: 1,
    unsigned_integer16: 2,
    unsigned_integer32: 4,
    unsigned_integer64: 8,
    real32: 4,
    real64: 8,
    complex_real32: 8,
    complex_real64: 16
  }

  @packed_types [
    :integer8,
    :integer16,
    :integer32,
    :integer64,
    :real32,
    :real64,
    :complex_real32,
    :complex_real64
  ]

  @spec to_byte(value_type()) :: byte()
  def to_byte(type), do: Map.fetch!(@type_to_byte, type)

  @spec from_byte(byte()) :: value_type()
  def from_byte(byte), do: Map.fetch!(@byte_to_type, byte)

  @spec element_size(value_type()) :: pos_integer()
  def element_size(type), do: Map.fetch!(@type_to_size, type)

  @spec packed_type?(value_type()) :: boolean()
  def packed_type?(type), do: type in @packed_types
end
