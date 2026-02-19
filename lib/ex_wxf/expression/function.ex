defmodule ExWxf.Expression.Function do
  @moduledoc "A Wolfram Language function application (e.g., `f[x, y]`)."

  @type t :: %__MODULE__{head: term(), parts: [term()]}

  @enforce_keys [:head]
  defstruct [:head, parts: []]
end
