defmodule ExWxf.Tokens do
  @moduledoc "WXF type token byte constants."

  @spec function() :: byte()
  def function, do: 0x66

  @spec symbol() :: byte()
  def symbol, do: 0x73

  @spec string() :: byte()
  def string, do: 0x53

  @spec binary_string() :: byte()
  def binary_string, do: 0x42

  @spec integer8() :: byte()
  def integer8, do: 0x43

  @spec integer16() :: byte()
  def integer16, do: 0x6A

  @spec integer32() :: byte()
  def integer32, do: 0x69

  @spec integer64() :: byte()
  def integer64, do: 0x4C

  @spec real64() :: byte()
  def real64, do: 0x72

  @spec big_integer() :: byte()
  def big_integer, do: 0x49

  @spec big_real() :: byte()
  def big_real, do: 0x52

  @spec packed_array() :: byte()
  def packed_array, do: 0xC1

  @spec numeric_array() :: byte()
  def numeric_array, do: 0xC2

  @spec association() :: byte()
  def association, do: 0x41

  @spec rule() :: byte()
  def rule, do: 0x2D

  @spec rule_delayed() :: byte()
  def rule_delayed, do: 0x3A
end
