defmodule PaperTrail.Serializer do
  @moduledoc """
  Serialization functions to create a version struct
  """

  alias Papertrail.Config
  alias PaperTrail.Opts
  alias PaperTrail.Version

  @type model :: struct() | Ecto.Changeset.t()
  @type options :: Keyword.t()
  @type primary_key :: integer() | String.t()

  @doc """
  Creates a version struct for a model and a specific changeset action
  """
  @spec make_version_struct(model(), :insert | :update | :delete, options()) :: Version.t()
  def make_version_struct(model, :insert, options) do
    originator = Config.originator()
    originator_ref = options[originator[:name]] || options[:originator]

    options
    |> version_schema()
    |> struct!(%{
      event: "insert",
      item_type: get_item_type(model),
      item_id: get_model_id(model, options),
      item_changes: serialize(model),
      originator_id: get_originator_id(originator_ref, options),
      origin: options[:origin],
      meta: options[:meta]
    })
    |> add_prefix(options[:prefix])
  end

  def make_version_struct(changeset, :update, options) do
    originator = Config.originator()
    originator_ref = options[originator[:name]] || options[:originator]

    options
    |> version_schema()
    |> struct!(%{
      event: "update",
      item_type: get_item_type(changeset),
      item_id: get_model_id(changeset, options),
      item_changes: serialize_changes(changeset),
      originator_id: get_originator_id(originator_ref, options),
      origin: options[:origin],
      meta: options[:meta]
    })
    |> add_prefix(options[:prefix])
  end

  def make_version_struct(model_or_changeset, :delete, options) do
    originator = Config.originator()
    originator_ref = options[originator[:name]] || options[:originator]

    options
    |> version_schema()
    |> struct!(%{
      event: "delete",
      item_type: get_item_type(model_or_changeset),
      item_id: get_model_id(model_or_changeset, options),
      item_changes: serialize(model_or_changeset),
      originator_id: get_originator_id(originator_ref, options),
      origin: options[:origin],
      meta: options[:meta]
    })
    |> add_prefix(options[:prefix])
  end

  defp get_originator_id(originator_ref, options) do
    case originator_ref do
      nil -> nil
      %{id: id} -> id
      model when is_struct(model) -> get_model_id(originator_ref, options)
    end
  end

  defp version_schema(opts), do: Keyword.get(opts, :version_schema, PaperTrail.Version)

  @doc """
  Returns the last primary key value of a table
  """
  @spec get_sequence_id(model() | String.t(), Keyword.t()) :: primary_key()
  def get_sequence_id(schema_changeset_or_table_name, opts \\ [])

  def get_sequence_id(%Ecto.Changeset{data: data}, opts) do
    get_sequence_id(data, opts)
  end

  def get_sequence_id(%schema{}, opts) do
    :source
    |> schema.__schema__()
    |> get_sequence_id(opts)
  end

  def get_sequence_id(table_name, opts) when is_binary(table_name) do
    Ecto.Adapters.SQL.query!(Opts.repo(opts), "select last_value FROM #{table_name}_id_seq").rows
    |> List.first()
    |> List.first()
  end
#
  @doc """
  Shows DB representation of an Ecto model, filters relationships and virtual attributes from an Ecto.Changeset or %ModelStruct{}
  """
  @spec serialize(nil | Ecto.Changeset.t() | struct()) :: nil | map()
  def serialize(nil), do: nil
  def serialize(%Ecto.Changeset{data: data}), do: serialize(data)
  def serialize(%_schema{} = model), do: Ecto.embedded_dump(model, :json)

  @doc """
  Dumps changes using Ecto fields
  """
  @spec serialize_changes(Ecto.Changeset.t()) :: map()
  def serialize_changes(%Ecto.Changeset{changes: changes} = changeset) do
    changeset
    |> serialize_model_changes()
    |> serialize()
    |> Map.take(Map.keys(changes))
  end

  @doc """
  Adds a prefix to the Ecto schema
  """
  @spec add_prefix(Ecto.Schema.schema(), nil | String.t()) :: Ecto.Schema.schema()
  def add_prefix(schema, nil), do: schema
  def add_prefix(schema, prefix), do: Ecto.put_meta(schema, prefix: prefix)

  @doc """
  Returns the model type, which is the last module name
  """
  @spec get_item_type(model()) :: String.t()
  def get_item_type(%Ecto.Changeset{data: data}), do: get_item_type(data)
  def get_item_type(%schema{}), do: schema |> Module.split() |> List.last()

  @doc """
  Returns the model primary id
  """
  @spec get_model_id(model(), Keyword.t()) :: primary_key()
  def get_model_id(%Ecto.Changeset{data: data}, options), do: get_model_id(data, options)

  def get_model_id(model, options) do
    {_, model_id} = model |> Ecto.primary_key() |> List.first()

    case Opts.version_schema(options).__schema__(:type, :item_id) do
      :integer -> model_id
      _ -> "#{model_id}"
    end
  end

  @spec serialize_model_changes(nil) :: nil
  defp serialize_model_changes(nil), do: nil

  @spec serialize_model_changes(Ecto.Changeset.t()) :: map()
  defp serialize_model_changes(%Ecto.Changeset{data: %schema{}} = changeset) do
    field_values = serialize_model_field_changes(changeset)
    embed_values = serialize_model_embed_changes(changeset)

    field_values
    |> Map.merge(embed_values)
    |> schema.__struct__()
  end

  defp serialize_model_field_changes(%Ecto.Changeset{data: %schema{}, changes: changes}) do
    change_keys = changes |> Map.keys() |> MapSet.new()

    field_keys =
      :fields
      |> schema.__schema__()
      |> MapSet.new()
      |> MapSet.intersection(change_keys)
      |> MapSet.to_list()

    Map.take(changes, field_keys)
  end

  defp serialize_model_embed_changes(%Ecto.Changeset{data: %schema{}, changes: changes}) do
    change_keys = changes |> Map.keys() |> MapSet.new()

    embed_keys =
      :embeds
      |> schema.__schema__()
      |> MapSet.new()
      |> MapSet.intersection(change_keys)
      |> MapSet.to_list()

    changes
    |> Map.take(embed_keys)
    |> Map.new(fn {key, value} ->
      case schema.__schema__(:embed, key) do
        %Ecto.Embedded{cardinality: :one} -> {key, serialize_model_changes(value)}
        %Ecto.Embedded{cardinality: :many} -> {key, Enum.map(value, &serialize_model_changes/1)}
      end
    end)
  end
end
