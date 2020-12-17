defmodule Hygeia.UserContext.User do
  @moduledoc """
  Model for User
  """

  use Hygeia, :model

  alias Hygeia.TenantContext.Tenant
  alias Hygeia.UserContext.Grant
  alias Hygeia.UserContext.Grant.Role

  @role_map Grant.Role.__enum_map__()

  @derive {Phoenix.Param, key: :uuid}

  @type empty :: %__MODULE__{
          uuid: String.t() | nil,
          email: String.t() | nil,
          display_name: String.t() | nil,
          iam_sub: String.t() | nil,
          grants: Ecto.Schema.has_many(Grant.t()) | nil,
          tenants: Ecto.Schema.has_many(Tenant.t()) | nil,
          inserted_at: NaiveDateTime.t() | nil,
          updated_at: NaiveDateTime.t() | nil
        }

  @type t :: %__MODULE__{
          uuid: String.t(),
          email: String.t(),
          display_name: String.t(),
          iam_sub: String.t(),
          grants: Ecto.Schema.has_many(Grant.t()),
          tenants: Ecto.Schema.has_many(Tenant.t()),
          inserted_at: NaiveDateTime.t(),
          updated_at: NaiveDateTime.t()
        }

  schema "users" do
    field :display_name, :string
    field :email, :string
    field :iam_sub, :string
    # TODO: Replace with Relation to Tenant to scope roles to tenant

    has_many :grants, Grant, foreign_key: :user_uuid, on_replace: :delete
    has_many :tenants, through: [:grants, :tenant]

    timestamps()
  end

  @spec changeset(user :: t | empty, attrs :: Hygeia.ecto_changeset_params()) :: Changeset.t()
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:email, :display_name, :iam_sub])
    |> cast_assoc(:grants)
    |> validate_required([:email, :display_name, :iam_sub])
    |> unique_constraint(:iam_sub)
    |> validate_email(:email)
  end

  @spec has_role?(user :: t, role :: Role.t(), tenant :: :any) :: boolean
  def has_role?(%__MODULE__{grants: grants}, role, :any)
      when role in @role_map and is_list(grants),
      do: Enum.any?(grants, &match?(%Grant{role: ^role}, &1))

  @spec has_role?(user :: t, role :: Role.t(), tenant :: Tenant.t()) :: boolean
  def has_role?(%__MODULE__{grants: grants}, role, %Tenant{uuid: tenant_uuid} = _tenant)
      when role in @role_map and is_list(grants),
      do: Enum.any?(grants, &match?(%Grant{role: ^role, tenant_uuid: ^tenant_uuid}, &1))

  @spec has_role?(user :: t, role :: Role.t(), tenant :: String.t()) :: boolean
  def has_role?(%__MODULE__{grants: grants}, role, tenant_uuid)
      when role in @role_map and is_list(grants) and is_binary(tenant_uuid),
      do: Enum.any?(grants, &match?(%Grant{role: ^role, tenant_uuid: ^tenant_uuid}, &1))

  @spec has_role?(user :: :anonymous, role :: Role.t(), tenant :: Tenant.t() | :any | String.t()) ::
          false
  def has_role?(:anonymous, _role, _tenant), do: false

  defimpl Hygeia.Authorization.Resource do
    alias Hygeia.UserContext.User

    @spec authorized?(
            resource :: User.t(),
            action :: :list | :details,
            user :: :anonymous | User.t(),
            meta :: %{atom() => term}
          ) :: boolean
    def authorized?(_resource_user, action, :anonymous, _meta)
        when action in [:list, :details],
        do: false

    def authorized?(_resource_user, action, user, _meta)
        when action in [:list, :details],
        do: Enum.any?([:viewer, :tracer, :supervisor, :admin], &User.has_role?(user, &1, :any))
  end
end
