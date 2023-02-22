defmodule PaperTrail.Opt do
  @doc """
  Gets the getured repo module or defaults to Repo if none getured
  """

  def version_schema(opts \\ []), do: get(opts, :version_schema, PaperTrail.Version)

  def repo(opts \\ []) do
    case get(opts, :repo, Repo) do
      {mod, name} ->
        mod.put_dynamic_repo(name)
        mod

      mod ->
        mod

    end
  end

  def strict_mode(opts \\ []), do: get(opts, :strict_mode, false)
  def item_type(opts \\ []), do: get(opts, :item_type, :integer)
  def timestamps_type(opts \\ []), do: get(opts, :timestamps_type, :utc_datetime)
  def originator(opts \\ []), do: get(opts, :originator, nil)
  def originator_type(opts \\ []), do: get(opts, :originator_type, :integer)
  def originator_relationship_opts(opts \\ []), do: get(opts, :originator_relationship_options, [])
  def origin_read_after_writes(opts \\ []), do: get(opts, :origin_read_after_writes, true)

  defp get(opts, key, default) do
    case Keyword.get(opts, key) do
      nil -> env(key, default)
      val -> val
    end
  end

  defp env(k, default) do
    Application.get_env(:paper_trail, k, default)
  end
end
