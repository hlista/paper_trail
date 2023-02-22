defmodule PaperTrail.Schema do
  @moduledoc """
  PaperTrail Schema

  ## How to Use

  ```elixir
  defmodule PaperTrail.Version do
    use PaperTrail.Schema
  end
  ```
  """

  @callback changeset(struct() | Ecto.Changeset.t(), map()) :: Ecto.Changeset.t()
  @callback create_changeset(map()) :: Ecto.Changeset.t()

  @callback by_count(Keyword.t()) :: Ecto.Query.t()
  @callback by_first(Keyword.t()) :: Ecto.Query.t()
  @callback by_last(Keyword.t()) :: Ecto.Query.t()
  @callback by_versions(struct() | map(), Keyword.t()) :: Ecto.Query.t()
  @callback by_versions(module(), non_neg_integer(), Keyword.t()) :: Ecto.Query.t()
  @callback by_version(struct() | map(), Keyword.t()) :: Ecto.Query.t()
  @callback by_version(module(), non_neg_integer(), Keyword.t()) :: Ecto.Query.t()

  @callback convert_item_type_to_existing_module(struct()) :: module()

  defmacro __using__(opts) do
    quote do
      opts = unquote(opts)

      item_id_type = Keyword.get(opts, :item_type, :integer)
      originator_id_type = Keyword.get(opts, :originator_type, :integer)
      origin_read_after_writes = Keyword.get(opts, :origin_read_after_writes, true)

      originator = Keyword.get(opts, :originator, nil)
      originator_relationship_opts = Keyword.get(opts, :originator_relationship_options, [])
      timestamps_type = Keyword.get(opts, :timestamps_type, :utc_datetime)

      use Ecto.Schema

      import Ecto.Changeset
      import Ecto.Query

      alias PaperTrail.Serializer

      @behaviour PaperTrail.Schema

      @type t :: %__MODULE__{}

      schema "versions" do
        field(:event, :string)
        field(:item_type, :string)
        field(:item_id, item_id_type)
        field(:item_changes, :map)
        field(:originator_id, originator_id_type)

        field(:origin, :string, read_after_writes: origin_read_after_writes)

        field(:meta, :map)

        if originator do
          belongs_to(
            originator[:name],
            originator[:model],
            Keyword.merge(originator_relationship_opts,
              define_field: false,
              foreign_key: :originator_id,
              type: originator_id_type
            )
          )
        end

        timestamps(updated_at: false, type: timestamps_type)
      end

      def changeset(model, params \\ %{}) do
        model
        |> cast(params, [:item_type, :item_id, :item_changes, :origin, :originator_id, :meta])
        |> validate_required([:event, :item_type, :item_id, :item_changes])
      end

      def create_changeset(params \\ %{}) do
        changeset(%__MODULE__{}, params)
      end

      @doc """
      Returns the count of all version records in the database
      """
      def by_count(options \\ []) do
        from(version in __MODULE__, select: count(version.id))
        |> maybe_put_prefix(options)
      end

      @doc """
      Returns the first version record in the database by :inserted_at
      """
      def by_first(options \\ []) do
        from(record in __MODULE__, limit: 1, order_by: [asc: :inserted_at])
        |> maybe_put_prefix(options)
      end

      @doc """
      Returns the last version record in the database by :inserted_at
      """
      def by_last(options \\ []) do
        from(record in __MODULE__, limit: 1, order_by: [desc: :inserted_at])
        |> maybe_put_prefix(options)
      end

      defp maybe_put_prefix(query, options) do
        case options[:prefix] do
          nil -> query
          prefix -> query |> Ecto.Queryable.to_query() |> Map.put(:prefix, prefix)
        end
      end

      @doc """
      ...
      """
      def by_versions(record, options) when is_map(record) do
        record.__struct__
        |> Module.split()
        |> List.last()
        |> version_query(Serializer.get_model_id(record, options), options)
      end

      def by_versions(module, id, options) do
        module
        |> Module.split()
        |> List.last()
        |> version_query(id, options)
      end

      @doc """
      ...
      """
      def by_version(record, options) when is_map(record) do
        record |> by_versions(options) |> last()
      end

      def by_version(model, id, options) do
        model |> by_versions(id, options) |> last()
      end

      @doc """
      ...
      """
      def convert_item_type_to_existing_module(version) do
        String.to_existing_atom("Elixir.#{version.item_type}")
      end

      defp version_query(item_type, id, options) do
        (from v in __MODULE__, where: v.item_type == ^item_type and v.item_id == ^id)
        |> maybe_transform_query(options)
      end

      defp maybe_transform_query(query, options) do
        case Keyword.pop(options, :query) do
          {nil, _} -> query
          {options, _} -> merge_query_args(query, options)
        end
      end

      defp merge_query_args(query, args) when is_map(args) do
        query |> Ecto.Queryable.to_query() |> Map.merge(args)
      end

      defp merge_query_args(query, args) do
        merge_query_args(query, Map.new(args))
      end
    end
  end
end
