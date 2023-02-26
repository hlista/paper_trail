defmodule PaperTrail.Opts do
  @doc """
  Gets the getured repo module or defaults to Repo if none getured
  """

  def strict_mode?(opts \\ []), do: Keyword.get(opts, :strict_mode, false)

  def version_schema(opts \\ []) do
    Keyword.get(opts, :version_schema, PaperTrail.Config.version_schema())
  end

  def repo(opts \\ []) do
    case Keyword.get(opts, :repo, PaperTrail.Config.repo()) do
      {mod, name} ->
        mod.put_dynamic_repo(name)
        mod

      mod ->
        mod

    end
  end

end
