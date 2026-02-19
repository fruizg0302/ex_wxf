defmodule ExWxf.Expression.BinaryString do
  @moduledoc "A raw byte sequence (Wolfram `ByteArray`)."

  @type t :: %__MODULE__{data: binary()}

  @enforce_keys [:data]
  defstruct [:data]
end
