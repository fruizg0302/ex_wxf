defmodule ExWxf.Expression.Symbol do
  @moduledoc "A Wolfram Language symbol (e.g., `List`, `Plus`, `` Global`x ``)."

  @type t :: %__MODULE__{name: String.t()}

  @enforce_keys [:name]
  defstruct [:name]
end
