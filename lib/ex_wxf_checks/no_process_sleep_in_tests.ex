defmodule ExWxfChecks.NoProcessSleepInTests do
  @moduledoc """
  EX9002: No `Process.sleep/1` in tests.
  """
  use Credo.Check,
    id: "EX9002",
    base_priority: :high,
    category: :warning,
    param_defaults: [],
    explanations: [
      check: """
      `Process.sleep/1` in tests indicates flaky timing-dependent assertions.
      Use `assert_receive`, `eventually`, or other deterministic waiting patterns.
      """
    ]

  @impl Credo.Check
  def run(%SourceFile{} = source_file, params) do
    if String.ends_with?(source_file.filename, "_test.exs") do
      issue_meta = IssueMeta.for(source_file, params)

      source_file
      |> Credo.Code.prewalk(&traverse(&1, &2, issue_meta))
      |> Enum.reject(&is_nil/1)
    else
      []
    end
  end

  defp traverse(
         {{:., _, [{:__aliases__, _, [:Process]}, :sleep]}, meta, _} = ast,
         issues,
         issue_meta
       ) do
    issue =
      format_issue(issue_meta,
        message: "Avoid `Process.sleep/1` in tests. Use deterministic waiting patterns.",
        line_no: meta[:line]
      )

    {ast, [issue | issues]}
  end

  defp traverse(ast, issues, _issue_meta) do
    {ast, issues}
  end
end
