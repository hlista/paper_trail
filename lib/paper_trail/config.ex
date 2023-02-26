defmodule PaperTrail.Config do
  @app :paper_trail

  def version_schema do
    Application.get_env(@app, :version_schema, PaperTrail.Version)
  end

  def repo do
    Application.get_env(@app, :repo, Repo)
  end

  def originator do
    Application.get_env(@app, :originator, nil)
  end

  def originator_relationship_opts do
    Application.get_env(@app, :originator_relationship_opts, [])
  end

  def origin_read_after_writes do
    Application.get_env(@app, :origin_read_after_writes, true)
  end

  def timestamps_type do
    Application.get_env(@app, :timestamps_type, :utc_datetime)
  end

  def originator_type do
    Application.get_env(@app, :originator_type, :integer)
  end

  def item_type do
    Application.get_env(@app, :item_type, :integer)
  end

end
