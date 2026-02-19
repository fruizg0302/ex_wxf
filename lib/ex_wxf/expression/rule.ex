defmodule ExWxf.Expression.Rule do
  @moduledoc "A rule within an association (`key -> value` or `key :> value`)."

  @type t :: %__MODULE__{key: term(), value: term(), delayed: boolean()}

  @enforce_keys [:key, :value]
  defstruct [:key, :value, delayed: false]
end
