defmodule ExWxf.Expression.BigReal do
  @moduledoc "An arbitrary-precision real, stored as a Wolfram InputForm string."

  @type t :: %__MODULE__{value: String.t()}

  @enforce_keys [:value]
  defstruct [:value]
end
