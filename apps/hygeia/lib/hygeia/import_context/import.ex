defmodule Hygeia.ImportContext.Import do
  @moduledoc """
  Import Model
  """
  use Hygeia, :model

  alias Hygeia.EctoType.LocalizedNaiveDatetime
  alias Hygeia.ImportContext.Import.Type
  alias Hygeia.ImportContext.Row
  alias Hygeia.TenantContext.Tenant

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
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  @derive {Phoenix.Param, key: :uuid}

  schema "imports" do
    field :type, Type
    field :change_date, LocalizedNaiveDatetime, autogenerate: true
    field :closed_at, :utc_datetime_usec

    belongs_to :tenant, Tenant, references: :uuid, foreign_key: :tenant_uuid
    has_many :rows, Row

    has_many :pending_rows, Row, where: [status: :pending]
    has_many :discarded_rows, Row, where: [status: :discarded]
    has_many :resolved_rows, Row, where: [status: :resolved]

    timestamps()
  end

  @spec changeset(
          case :: empty | t | Ecto.Changeset.t(t | empty),
          attrs :: Hygeia.ecto_changeset_params()
        ) ::
          Ecto.Changeset.t(t)
  def changeset(import, attrs) do
    import
    |> cast(attrs, [:type])
    |> validate_required([:type])
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
