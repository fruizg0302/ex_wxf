defmodule ExWxf.Expression.Association do
  @moduledoc "A Wolfram Language association (`<| key -> val, ... |>`)."

  @type t :: %__MODULE__{rules: [ExWxf.Expression.Rule.t()]}

  defstruct rules: []
end
