defmodule PaperTrail.SchemaContext do

  alias PaperTrail.Opt

  @doc """
  ...
  """
  def get_versions(record, opts) do
    record
    |> Opt.version_schema(opts).by_versions(opts)
    |> Opt.repo(opts).all(ecto_opts(opts))
  end

  def get_versions(version, id, opts) do
    version
    |> Opt.version_schema(opts).by_versions(id, opts)
    |> Opt.repo(opts).all(ecto_opts(opts))
  end

  @doc """
  ...
  """
  def get_version(record, opts) do
    record
    |> Opt.version_schema(opts).by_version(opts)
    |> Opt.repo(opts).one(ecto_opts(opts))
  end

  def get_version(module, id, opts) do
    module
    |> Opt.version_schema(opts).by_version(id, opts)
    |> Opt.repo(opts).one(ecto_opts(opts))
  end

  @doc """
  ...
  """
  def get_current_model(version, opts \\ []) do
    version
    |> Opt.version_schema(opts).convert_item_type_to_existing_module()
    |> Opt.repo(opts).get(ecto_opts(opts))
  end

  @doc """
  ...
  """
  def get_count(opts \\ []) do
    opts
    |> Opt.version_schema(opts).by_count(opts)
    |> Opt.repo(opts).one(ecto_opts(opts))
  end

  @doc """
  ...
  """
  def get_first(opts \\ []) do
    opts
    |> Opt.version_schema(opts).by_first(opts)
    |> Opt.repo(opts).one(ecto_opts(opts))
  end

  @doc """
  ...
  """
  def get_last(opts \\ []) do
    opts
    |> Opt.version_schema(opts).by_last(opts)
    |> Opt.repo(opts).one(ecto_opts(opts))
  end

  defp ecto_opts(opts), do: Keyword.get(opts, :ecto_options, [])

end
