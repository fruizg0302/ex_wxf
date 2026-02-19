defmodule ExWxf.Expression.NumericArray do
  @moduledoc "A homogeneous numeric array (all value types supported)."

  @type t :: %__MODULE__{
          type: atom(),
          dimensions: [pos_integer()],
          data: binary()
        }

  @enforce_keys [:type, :dimensions, :data]
  defstruct [:type, :dimensions, :data]
end
