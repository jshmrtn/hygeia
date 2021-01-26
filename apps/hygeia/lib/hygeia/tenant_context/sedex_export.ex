defmodule Hygeia.TenantContext.SedexExport do
  @moduledoc """
  Model for edex Exports
  """

  use Hygeia, :model

  import EctoEnum

  alias Hygeia.TenantContext.Tenant

  defenum Status, :sedex_export_status, [:missed, :sent, :received, :error]

  @derive {Phoenix.Param, key: :uuid}

  @type empty :: %__MODULE__{
          uuid: String.t() | nil,
          scheduling_date: NaiveDateTime.t() | nil,
          status: Status.t() | nil,
          tenant: Ecto.Schema.belongs_to(Tenant.t()) | nil,
          tenant_uuid: String.t() | nil,
          inserted_at: NaiveDateTime.t() | nil,
          updated_at: NaiveDateTime.t() | nil
        }

  @type t :: %__MODULE__{
          uuid: String.t(),
          scheduling_date: NaiveDateTime.t(),
          status: Status.t(),
          tenant: Ecto.Schema.belongs_to(Tenant.t()),
          tenant_uuid: String.t(),
          inserted_at: NaiveDateTime.t(),
          updated_at: NaiveDateTime.t()
        }

  schema "sedex_exports" do
    field :scheduling_date, :naive_datetime
    field :status, Status

    belongs_to :tenant, Tenant, references: :uuid, foreign_key: :tenant_uuid

    timestamps()
  end

  @spec changeset(sedex_export :: t | empty, attrs :: Hygeia.ecto_changeset_params()) ::
          Changeset.t()
  def changeset(sedex_export, attrs),
    do:
      sedex_export
      |> cast(attrs, [:scheduling_date, :status])
      |> validate_required([:scheduling_date, :status])
      |> assoc_constraint(:tenant)

  defimpl Hygeia.Authorization.Resource do
    alias Hygeia.TenantContext.SedexExport
    alias Hygeia.UserContext.User

    @spec authorized?(
            resource :: SedexExport.t(),
            action :: :list,
            user :: :anonymous | User.t(),
            meta :: %{atom() => term}
          ) :: boolean
    def authorized?(_sedex_export, :list, :anonymous, _meta), do: false

    def authorized?(_sedex_export, :list, %User{} = user, %{tenant: tenant}),
      do: User.has_role?(user, :admin, tenant) or User.has_role?(user, :webmaster, :any)
  end
end
