defmodule Hygeia.ImportContext.Import do
  @moduledoc """
  Import Model
  """
  use Hygeia, :model

  alias Hygeia.EctoType.LocalizedNaiveDatetime
  alias Hygeia.ImportContext.Import.Type
  alias Hygeia.ImportContext.Row
  alias Hygeia.ImportContext.RowLink
  alias Hygeia.TenantContext.Tenant
  alias Hygeia.UserContext.User

  @type empty :: %__MODULE__{
          uuid: Ecto.UUID.t() | nil,
          type: Type.t() | nil,
          tenant_uuid: Ecto.UUID.t() | nil,
          tenant: Ecto.Schema.belongs_to(Tenant.t()) | nil,
          rows: Ecto.Schema.has_many(Row.t()) | nil,
          pending_rows: Ecto.Schema.has_many(Row.t()) | nil,
          discarded_rows: Ecto.Schema.has_many(Row.t()) | nil,
          resolved_rows: Ecto.Schema.has_many(Row.t()) | nil,
          closed_at: DateTime.t() | nil,
          default_tracer_uuid: Ecto.UUID.t() | nil,
          default_tracer: Ecto.Schema.belongs_to(User.t()) | nil,
          default_supervisor_uuid: Ecto.UUID.t() | nil,
          default_supervisor: Ecto.Schema.belongs_to(User.t()) | nil,
          filename: String.t() | nil,
          inserted_at: DateTime.t() | nil,
          updated_at: DateTime.t() | nil
        }

  @type t :: %__MODULE__{
          uuid: Ecto.UUID.t(),
          type: Type.t(),
          tenant_uuid: Ecto.UUID.t(),
          tenant: Ecto.Schema.belongs_to(Tenant.t()),
          rows: Ecto.Schema.has_many(Row.t()),
          pending_rows: Ecto.Schema.has_many(Row.t()),
          discarded_rows: Ecto.Schema.has_many(Row.t()),
          resolved_rows: Ecto.Schema.has_many(Row.t()),
          closed_at: DateTime.t() | nil,
          default_tracer_uuid: Ecto.UUID.t() | nil,
          default_tracer: Ecto.Schema.belongs_to(User.t()) | nil,
          default_supervisor_uuid: Ecto.UUID.t() | nil,
          default_supervisor: Ecto.Schema.belongs_to(User.t()) | nil,
          filename: String.t(),
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  @derive {Phoenix.Param, key: :uuid}

  schema "imports" do
    field :type, Type
    field :change_date, LocalizedNaiveDatetime, autogenerate: true
    field :closed_at, :utc_datetime_usec
    field :filename, :string

    belongs_to :tenant, Tenant, references: :uuid, foreign_key: :tenant_uuid

    many_to_many :rows, Row,
      join_through: RowLink,
      join_keys: [import_uuid: :uuid, row_uuid: :uuid]

    many_to_many :pending_rows, Row,
      join_through: RowLink,
      join_keys: [import_uuid: :uuid, row_uuid: :uuid],
      where: [status: :pending]

    many_to_many :discarded_rows, Row,
      join_through: RowLink,
      join_keys: [import_uuid: :uuid, row_uuid: :uuid],
      where: [status: :discarded]

    many_to_many :resolved_rows, Row,
      join_through: RowLink,
      join_keys: [import_uuid: :uuid, row_uuid: :uuid],
      where: [status: :resolved]

    belongs_to :default_tracer, User, references: :uuid, foreign_key: :default_tracer_uuid
    belongs_to :default_supervisor, User, references: :uuid, foreign_key: :default_supervisor_uuid

    timestamps()
  end

  @spec changeset(
          case :: empty | t | Ecto.Changeset.t(t | empty),
          attrs :: Hygeia.ecto_changeset_params()
        ) ::
          Ecto.Changeset.t(t)
  def changeset(import, attrs) do
    import
    |> cast(attrs, [:type, :default_tracer_uuid, :default_supervisor_uuid, :filename])
    |> cast_assoc(:rows)
    |> validate_required([:type])
    |> check_constraint(:default_tracer_uuid, name: :default_tracer_uuid)
    |> check_constraint(:default_supervisor_uuid, name: :default_supervisor_uuid)
  end

  defimpl Hygeia.Authorization.Resource do
    alias Hygeia.CaseContext.Person
    alias Hygeia.ImportContext.Import
    alias Hygeia.UserContext.User

    @spec preload(resource :: Import.t()) :: Import.t()
    def preload(resource), do: resource

    @spec authorized?(
            resource :: Import.t(),
            action ::
              :create | :list | :details | :update | :delete | :versioning | :deleted_versioning,
            user :: :anonymous | User.t() | Person.t(),
            meta :: %{atom() => term}
          ) :: boolean
    def authorized?(_import, action, :anonymous, _meta)
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

    def authorized?(_import, action, %Person{}, _meta)
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

    def authorized?(%Import{tenant_uuid: tenant_uuid}, action, user, _meta)
        when action in [:details, :update, :delete, :tenant_uuid, :versioning],
        do:
          Enum.any?(
            [:super_user, :admin],
            &User.has_role?(user, &1, tenant_uuid)
          )

    def authorized?(_import, action, user, %{tenant: tenant})
        when action in [:create, :list, :deleted_versioning],
        do: Enum.any?([:supervisor, :admin], &User.has_role?(user, &1, tenant))
  end
end
