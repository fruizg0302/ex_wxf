defmodule ExWxf.Expression.PackedArray do
  @moduledoc "A homogeneous numeric array (restricted value types)."

  @type t :: %__MODULE__{
          type: atom(),
          dimensions: [pos_integer()],
          data: binary()
        }

  @enforce_keys [:type, :dimensions, :data]
  defstruct [:type, :dimensions, :data]
end
