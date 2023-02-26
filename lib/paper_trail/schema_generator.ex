defmodule PaperTrail.SchemaGenerator do
  @moduledoc """
  PaperTrail Schema
  """

  defstruct [:app_name]

  def run(%PaperTrail.SchemaGenerator{} = state) do
    bindings =
      state
      |> Map.from_struct()
      |> Map.to_list()

    "paper_trail_version"
    |> template_path()
    |> evaluate_template(bindings)
  end

  @locals_without_parens [
    field: :*,
    belongs_to: :*,
    timestamps: :*
  ]

  defp template_path(template_name) do
    Path.join(:code.priv_dir(:paper_trail), "templates/#{template_name}.ex.eex")
  end

  defp evaluate_template(template_path, assigns) do
    template_path
    |> EEx.eval_file(assigns)
    |> attempt_to_format_template
  end

  defp attempt_to_format_template(code) do
    Code.format_string!(code, locals_without_parens: @locals_without_parens)

    rescue
      SyntaxError ->
        reraise "Error inside the resulting template: \n #{code}", __STACKTRACE__
  end

end
