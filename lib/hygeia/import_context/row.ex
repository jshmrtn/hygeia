defmodule Hygeia.ImportContext.Row do
  @moduledoc """
  Import Row Model
  """
  use Hygeia, :model

  alias Hygeia.CaseContext.Case
  alias Hygeia.ImportContext.Import
  alias Hygeia.ImportContext.Row.Status
  alias Hygeia.ImportContext.RowLink
  alias Hygeia.TenantContext.Tenant

  @type empty :: %__MODULE__{
          uuid: Ecto.UUID.t() | nil,
          corrected: map | nil,
          data: map | nil,
          identifiers: map | nil,
          status: Status.t() | nil,
          case_uuid: Ecto.UUID.t() | nil,
          case: Ecto.Schema.belongs_to(Case.t()) | nil,
          imports: Ecto.Schema.has_many(Import.t()) | nil,
          tenant: Ecto.Schema.has_one(Tenant.t()) | nil,
          inserted_at: DateTime.t() | nil,
          updated_at: DateTime.t() | nil
        }

  @type t :: %__MODULE__{
          uuid: Ecto.UUID.t(),
          corrected: map | nil,
          data: map,
          identifiers: map,
          status: Status.t(),
          case_uuid: Ecto.UUID.t() | nil,
          case: Ecto.Schema.belongs_to(Case.t()) | nil,
          imports: Ecto.Schema.has_many(Import.t()),
          tenant: Ecto.Schema.has_one(Tenant.t()),
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  @derive {Phoenix.Param, key: :uuid}

  schema "import_rows" do
    field :corrected, :map
    field :identifiers, :map
    field :data, :map
    field :status, Status, default: :pending

    many_to_many :imports, Import,
      join_through: RowLink,
      join_keys: [row_uuid: :uuid, import_uuid: :uuid]

    belongs_to :import, Import, references: :uuid, foreign_key: :import_uuid

    has_one :tenant, through: [:import, :tenant]
    belongs_to :case, Case, references: :uuid, foreign_key: :case_uuid

    timestamps()
  end

  @doc false
  @spec changeset(row :: t | empty, attrs :: Hygeia.ecto_changeset_params()) ::
          Changeset.t(t | empty)
  def changeset(row, attrs) do
    row
    |> cast(attrs, [:data, :corrected, :identifiers, :status, :import_uuid, :case_uuid])
    |> cast_assoc(:imports)
    |> validate_required([:data, :identifiers, :status, :import_uuid])
    |> unique_constraint([:data])
  end

  @spec get_corrected_data(row :: t, predecessor :: t | nil) :: map
  def get_corrected_data(row, predecessor)

  def get_corrected_data(%__MODULE__{data: data, corrected: corrected}, nil),
    do: get_corrected_data(data, corrected, %{}, %{})

  def get_corrected_data(%__MODULE__{data: data, corrected: corrected}, %__MODULE__{
        data: predecessor_data,
        corrected: predecessor_corrected
      }),
      do: get_corrected_data(data, corrected, predecessor_data, predecessor_corrected)

  defp get_corrected_data(data, corrected, predecessor_data, predecessor_corrected)

  defp get_corrected_data(data, nil, predecessor_data, predecessor_corrected),
    do: get_corrected_data(data, %{}, predecessor_data, predecessor_corrected)

  defp get_corrected_data(data, corrected, predecessor_data, nil),
    do: get_corrected_data(data, corrected, predecessor_data, %{})

  defp get_corrected_data(data, corrected, predecessor_data, predecessor_corrected) do
    data
    |> zip_corrections_and_predecessor(corrected, predecessor_data, predecessor_corrected)
    |> Map.new(&zip_to_map/1)
  end

  @spec get_changes(row :: t, predecessor :: t | nil) :: map
  def get_changes(row, predecessor)

  def get_changes(%__MODULE__{data: data, corrected: corrected}, nil),
    do: get_changes(data, corrected, %{}, %{})

  def get_changes(%__MODULE__{data: data, corrected: corrected}, %__MODULE__{
        data: predecessor_data,
        corrected: predecessor_corrected
      }),
      do: get_changes(data, corrected, predecessor_data, predecessor_corrected)

  defp get_changes(data, corrected, predecessor_data, predecessor_corrected)

  defp get_changes(data, nil, predecessor_data, predecessor_corrected),
    do: get_changes(data, %{}, predecessor_data, predecessor_corrected)

  defp get_changes(data, corrected, predecessor_data, nil),
    do: get_changes(data, corrected, predecessor_data, %{})

  defp get_changes(data, corrected, predecessor_data, predecessor_corrected) do
    data
    |> zip_corrections_and_predecessor(corrected, predecessor_data, predecessor_corrected)
    |> Enum.reject(
      &match?({_key, {{:ok, data}, :error, {:ok, data}, _predecessor_corrected}}, &1)
    )
    |> Map.new(&zip_to_map/1)
  end

  defp zip_corrections_and_predecessor(data, corrected, predecessor_data, predecessor_corrected) do
    [data, corrected, predecessor_data, predecessor_corrected]
    |> Enum.flat_map(&Map.keys/1)
    |> Enum.uniq()
    |> Enum.map(
      &{&1,
       {Map.fetch(data, &1), Map.fetch(corrected, &1), Map.fetch(predecessor_data, &1),
        Map.fetch(predecessor_corrected, &1)}}
    )
  end

  defp zip_to_map(field)

  defp zip_to_map({key, {_data, {:ok, corrected}, _predecessor_data, _predecessor_corrected}}),
    do: {key, corrected}

  defp zip_to_map({key, {{:ok, data}, :error, _predecessor_data, _predecessor_corrected}}),
    do: {key, data}

  defp zip_to_map({key, {:error, :error, _predecessor_data, _predecessor_corrected}}),
    do: {key, nil}

  @spec get_change_field(changes :: map, path :: [String.t()], default :: default) ::
          default | term
        when default: term
  def get_change_field(changes, path, default \\ nil) do
    Enum.reduce_while(path, changes, fn path_part, changes ->
      changes
      |> Enum.find(:error, fn
        {^path_part, _value} -> true
        {key, _value} -> key |> String.downcase() |> String.trim() == path_part
      end)
      |> case do
        :error -> {:halt, default}
        {_key, value} -> {:cont, value}
      end
    end)
  end

  @spec get_data_field(row :: t, path :: [String.t()], default :: default) :: default | term
        when default: term
  def get_data_field(%__MODULE__{data: data, corrected: corrected}, path, default \\ nil) do
    (is_map(corrected) && get_change_field(corrected, path, default)) ||
      get_change_field(data, path, default)
  end

  defimpl Hygeia.Authorization.Resource do
    alias Hygeia.CaseContext.Person
    alias Hygeia.ImportContext.Row
    alias Hygeia.Repo
    alias Hygeia.UserContext.User

    @spec preload(resource :: Row.t()) :: Row.t()
    def preload(resource), do: Repo.preload(resource, :tenant)

    @spec authorized?(
            resource :: Row.t(),
            action ::
              :create | :list | :details | :update | :delete | :versioning | :deleted_versioning,
            user :: :anonymous | User.t() | Person.t(),
            meta :: %{atom() => term}
          ) :: boolean
    def authorized?(_row, action, :anonymous, _meta)
        when action in [
               :list,
               :create,
               :details,
               :update,
               :delete,
               :versioning,
               :deleted_versioning
             ],
        do: false

    def authorized?(_row, action, %Person{}, _meta)
        when action in [
               :list,
               :create,
               :details,
               :update,
               :delete,
               :versioning,
               :deleted_versioning
             ],
        do: false

    def authorized?(%Row{tenant: tenant}, action, user, _meta)
        when action in [:details, :update, :delete, :versioning],
        do:
          Enum.any?(
            [:super_user, :admin],
            &User.has_role?(user, &1, tenant)
          )

    def authorized?(_row, action, user, %{tenant: tenant})
        when action in [:create, :list, :deleted_versioning],
        do: Enum.any?([:supervisor, :admin], &User.has_role?(user, &1, tenant))

    def authorized?(_row, action, user, %{import: %Import{tenant_uuid: tenant_uuid}})
        when action in [:create, :list, :deleted_versioning],
        do: Enum.any?([:supervisor, :admin], &User.has_role?(user, &1, tenant_uuid))
  end
end
