defmodule ExWxfChecks.NoNestedModules do
  @moduledoc """
  EX9001: One `defmodule` per file.
  """
  use Credo.Check,
    id: "EX9001",
    base_priority: :high,
    category: :design,
    param_defaults: [],
    explanations: [
      check: """
      Each file should contain exactly one `defmodule`. Nested modules make
      files harder to find and violate the one-module-per-file convention.
      """
    ]

  @impl Credo.Check
  def run(%SourceFile{} = source_file, params) do
    issue_meta = IssueMeta.for(source_file, params)

    source_file
    |> Credo.Code.prewalk(&traverse(&1, &2, issue_meta))
    |> Enum.reject(&is_nil/1)
    |> then(fn issues ->
      if length(issues) > 1 do
        Enum.drop(issues, 1)
      else
        []
      end
    end)
  end

  defp traverse({:defmodule, meta, _} = ast, issues, issue_meta) do
    issue = issue_for(issue_meta, meta[:line])
    {ast, [issue | issues]}
  end

  defp traverse(ast, issues, _issue_meta) do
    {ast, issues}
  end

  defp issue_for(issue_meta, line_no) do
    format_issue(issue_meta,
      message:
        "File contains more than one `defmodule`. Extract nested modules to separate files.",
      line_no: line_no
    )
  end
end
