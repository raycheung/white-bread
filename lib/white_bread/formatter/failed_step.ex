defprotocol WhiteBread.Formatter.FailedStep do
  def text(failure_type, failing_step, failure_data)
end

defimpl WhiteBread.Formatter.FailedStep, for: Atom do
  alias WhiteBread.CodeGenerator
  alias WhiteBread.Outputers.Style

  def text(:missing_step, step, _error) do
    %{text: step_text} = step
    code_to_implement = CodeGenerator.Step.regex_code_for_step(step)
    Style.info "undefined step: #{step_text}"
    <> " implement with\n\n" <> code_to_implement
  end

  def text(:no_clause_match, step, error) do
    %{text: step_text} = step
    {_clause_match_error, stacktrace} = error
    trace_message = Exception.format_stacktrace(stacktrace)
    Style.failed "unable to match clauses: #{step_text}:\n" <>
    "trace:\n#{trace_message}"
  end

  def text(:other_failure, step, {other_failure, stacktrace}) do
    %{text: step_text} = step
    trace_message = Exception.format_stacktrace(stacktrace)
    "execution failure: #{step_text}:\n" <>
    Style.exception "Exception: #{Exception.message other_failure}: \n" <>
    trace_message
  end
end

defimpl WhiteBread.Formatter.FailedStep,
for: [ESpec.AssertionError, ExUnit.AssertionError] do
  def text(_, step, assertion_failure) do
    %{text: step_text} = step
    assestion_message = ExUnit.Formatter.format_assertion_error(assertion_failure, :infinity, &formatter/2, "")
    "#{step_text}: #{assestion_message}"
  end

  defp colorize(escape, string) do
    [escape | string]
    |> IO.ANSI.format
    |> IO.iodata_to_binary
  end

  defp formatter(:diff_enabled?, _),
    do: true

  defp formatter(:error_info, msg),
    do: colorize(:red, msg)

  defp formatter(:extra_info, msg),
    do: colorize(:cyan, msg)

  defp formatter(:location_info, msg),
    do: colorize([:bright, :black], msg)

  defp formatter(:diff_delete, msg),
    do: colorize(:red, msg)

  defp formatter(:diff_insert, msg),
    do: colorize(:green, msg)

  defp formatter(_,  msg),
    do: msg
end
