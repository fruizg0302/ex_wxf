defmodule ExWxf.DecodeError do
  @moduledoc "Raised when WXF decoding fails."
  defexception [:message, :binary]

  @type t :: %__MODULE__{message: String.t(), binary: binary() | nil}

  @impl Exception
  @spec exception(keyword()) :: t()
  def exception(opts) do
    message = Keyword.get(opts, :message, "decoding failed")
    bin = Keyword.get(opts, :binary)
    %__MODULE__{message: message, binary: bin}
  end
end
