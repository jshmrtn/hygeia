defmodule Hygeia.UserContext.Grant do
  @moduledoc """
  Model for Grant
  """

  use Hygeia, :model

  import EctoEnum

  alias Hygeia.TenantContext.Tenant
  alias Hygeia.UserContext.User

  defenum Role, :grant_role, ["tracer", "supervisor", "admin", "webmaster", "statistics_viewer"]

  @type empty :: %__MODULE__{
          user: Ecto.Schema.belongs_to(User.t()) | nil,
          user_uuid: String.t() | nil,
          tenant: Ecto.Schema.belongs_to(Tenant.t()) | nil,
          tenant_uuid: String.t() | nil,
          role: Role.t() | nil,
          inserted_at: NaiveDateTime.t() | nil,
          updated_at: NaiveDateTime.t() | nil
        }

  @type t :: %__MODULE__{
          user: Ecto.Schema.belongs_to(User.t()),
          user_uuid: String.t(),
          tenant: Ecto.Schema.belongs_to(Tenant.t()),
          tenant_uuid: String.t(),
          role: Role.t(),
          inserted_at: NaiveDateTime.t(),
          updated_at: NaiveDateTime.t()
        }

  @primary_key false
  schema "user_grants" do
    field :role, Role, primary_key: true

    belongs_to :user, User, references: :uuid, foreign_key: :user_uuid, primary_key: true
    belongs_to :tenant, Tenant, references: :uuid, foreign_key: :tenant_uuid, primary_key: true

    timestamps()
  end

  @spec changeset(grant :: t | empty, attrs :: Hygeia.ecto_changeset_params()) :: Changeset.t()
  def changeset(grant, attrs) do
    grant
    |> cast(attrs, [:user_uuid, :tenant_uuid, :role])
    |> validate_required([:role])
    |> assoc_constraint(:user)
    |> assoc_constraint(:tenant)
    |> unique_constraint([:user_uuid, :tenant_uuid, :role], name: :user_grants_pkey)
  end
end
