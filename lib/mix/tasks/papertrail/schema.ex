defmodule Mix.Tasks.Papertrail.Gen.Schema do
  use Mix.Task

  alias Mix.PaperTrailGeneratorUtils

  @shortdoc "Generates a PaperTrail Version Schema"

  @moduledoc """
  Generates an Absinthe Schema

  ### Options

  TODO: ...

  ### Example
  ```bash
  mix papertrail.gen.schema
    --app-name MyApp
    --path ./lib/my_app/version.ex
  ```
  """

  def run(args) do
    PaperTrailGeneratorUtils.ensure_not_in_umbrella!("papertrail.gen.schema")

    {args, _extra_args} = PaperTrailGeneratorUtils.parse_path_opts(args, [
      path: :string,
      app_name: :string
    ])

    path = Keyword.get(args, :path, "./lib/#{Macro.underscore(args[:app_name])}/version.ex")

    args
    |> Map.new()
    |> serialize_to_schema_struct()
    |> PaperTrail.SchemaGenerator.run()
    |> PaperTrailGeneratorUtils.write_template(path)
  end

  defp serialize_to_schema_struct(args) do
    %PaperTrail.SchemaGenerator{app_name: args[:app_name]}
  end

end
