defmodule ExWxf.EncodeError do
  @moduledoc "Raised when WXF encoding fails."
  defexception [:message, :term]

  @type t :: %__MODULE__{message: String.t(), term: term()}

  @impl Exception
  @spec exception(keyword()) :: t()
  def exception(opts) do
    message = Keyword.get(opts, :message, "encoding failed")
    term = Keyword.get(opts, :term)
    %__MODULE__{message: message, term: term}
  end
end
