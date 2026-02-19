defmodule ExWxf.Expression.BigInteger do
  @moduledoc "An arbitrary-precision integer, stored as a decimal digit string."

  @type t :: %__MODULE__{value: String.t()}

  @enforce_keys [:value]
  defstruct [:value]
end
