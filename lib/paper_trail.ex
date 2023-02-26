defmodule PaperTrail do
  alias PaperTrail.{
    Opts,
    Serializer,
    Version
  }

  def get_versions(record, opts) do
    record
    |> Opts.version_schema(opts).by_versions(opts)
    |> Opts.repo(opts).all(ecto_opts(opts))
  end

  def get_versions(version, id, opts) do
    version
    |> Opts.version_schema(opts).by_versions(id, opts)
    |> Opts.repo(opts).all(ecto_opts(opts))
  end

  @doc """
  ...
  """
  def get_version(record, opts) do
    record
    |> Opts.version_schema(opts).by_version(opts)
    |> Opts.repo(opts).one(ecto_opts(opts))
  end

  def get_version(module, id, opts) do
    module
    |> Opts.version_schema(opts).by_version(id, opts)
    |> Opts.repo(opts).one(ecto_opts(opts))
  end

  @doc """
  ...
  """
  def get_current_model(version, opts \\ []) do
    version
    |> Opts.version_schema(opts).convert_item_type_to_existing_module()
    |> Opts.repo(opts).get(ecto_opts(opts))
  end

  @doc """
  ...
  """
  def get_count(opts \\ []) do
    opts
    |> Opts.version_schema(opts).by_count(opts)
    |> Opts.repo(opts).one(ecto_opts(opts))
  end

  @doc """
  ...
  """
  def get_first(opts \\ []) do
    opts
    |> Opts.version_schema(opts).by_first(opts)
    |> Opts.repo(opts).one(ecto_opts(opts))
  end

  @doc """
  ...
  """
  def get_last(opts \\ []) do
    opts
    |> Opts.version_schema(opts).by_last(opts)
    |> Opts.repo(opts).one(ecto_opts(opts))
  end

  defp ecto_opts(opts), do: Keyword.get(opts, :ecto_options, [])

  defdelegate make_version_struct(version, model, options), to: Serializer
  defdelegate serialize(data), to: Serializer
  defdelegate get_sequence_id(table_name), to: Serializer
  defdelegate add_prefix(schema, prefix), to: Serializer
  defdelegate get_item_type(data), to: Serializer
  defdelegate get_model_id(model, options), to: Serializer

  @doc """
  Inserts a record to the database with a related version insertion in one transaction
  """
  @spec insert(
          changeset :: Ecto.Changeset.t(model),
          options :: Keyword.t()
        ) ::
          {:ok, %{model: model, version: Version.t()}} | {:error, Ecto.Changeset.t(model) | term}
        when model: struct
  def insert(changeset, options \\ []) do
    PaperTrail.Multi.new()
    |> PaperTrail.Multi.insert(changeset, options)
    |> PaperTrail.Multi.commit(options)
  end

  @doc """
  Same as insert/2 but returns only the model struct or raises if the changeset is invalid.
  """
  @spec insert!(changeset :: Ecto.Changeset.t(model), options :: Keyword.t()) :: model
        when model: struct
  def insert!(changeset, options \\ []) do
    changeset
    |> insert(options)
    |> model_or_error(:insert)
  end

  @doc """
  Upserts a record to the database with a related version insertion in one transaction.
  """
  @spec insert_or_update(changeset :: Ecto.Changeset.t(model), options :: Keyword.t()) ::
          {:ok, %{model: model, version: Version.t()}} | {:error, Ecto.Changeset.t(model) | term}
        when model: struct
  def insert_or_update(changeset, options \\ []) do
    PaperTrail.Multi.new()
    |> PaperTrail.Multi.insert_or_update(changeset, options)
    |> PaperTrail.Multi.commit()
  end

  @doc """
  Same as insert_or_update/2 but returns only the model struct or raises if the changeset is invalid.
  """
  @spec insert_or_update!(changeset :: Ecto.Changeset.t(model), options :: Keyword.t()) :: model
        when model: struct
  def insert_or_update!(changeset, options \\ []) do
    changeset
    |> insert_or_update(options)
    |> model_or_error(:insert_or_update)
  end

  @doc """
  Updates a record from the database with a related version insertion in one transaction
  """
  @spec update(changeset :: Ecto.Changeset.t(model), options :: Keyword.t()) ::
          {:ok, %{model: model, version: Version.t()}} | {:error, Ecto.Changeset.t(model) | term}
        when model: struct
  def update(changeset, options \\ []) do
    PaperTrail.Multi.new()
    |> PaperTrail.Multi.update(changeset, options)
    |> PaperTrail.Multi.commit()
  end

  @doc """
  Same as update/2 but returns only the model struct or raises if the changeset is invalid.
  """
  @spec update!(changeset :: Ecto.Changeset.t(model), options :: Keyword.t()) :: model
        when model: struct
  def update!(changeset, options \\ []) do
    changeset
    |> update(options)
    |> model_or_error(:update)
  end

  @doc """
  Deletes a record from the database with a related version insertion in one transaction
  """
  @spec delete(model_or_changeset :: model | Ecto.Changeset.t(model), options :: Keyword.t()) ::
          {:ok, %{model: model, version: Version.t()}} | {:error, Ecto.Changeset.t(model) | term}
        when model: struct
  def delete(model_or_changeset, options \\ []) do
    PaperTrail.Multi.new()
    |> PaperTrail.Multi.delete(model_or_changeset, options)
    |> PaperTrail.Multi.commit()
  end

  @doc """
  Same as delete/2 but returns only the model struct or raises if the changeset is invalid.
  """
  @spec delete!(model_or_changeset :: model | Ecto.Changeset.t(model), options :: Keyword.t()) ::
          model
        when model: struct
  def delete!(model_or_changeset, options \\ []) do
    model_or_changeset
    |> delete(options)
    |> model_or_error(:delete)
  end

  @spec model_or_error(
          result :: {:ok, %{required(:model) => model, optional(any()) => any()}},
          action :: :insert | :insert_or_update | :update | :delete
        ) ::
          model
        when model: struct()
  defp model_or_error({:ok, %{model: model}}, _action) do
    model
  end

  @spec model_or_error(
          result :: {:error, reason :: term},
          action :: :insert | :insert_or_update | :update | :delete
        ) :: no_return
  defp model_or_error({:error, %Ecto.Changeset{} = changeset}, action) do
    raise Ecto.InvalidChangesetError, action: action, changeset: changeset
  end

  defp model_or_error({:error, reason}, _action) do
    raise reason
  end
end
