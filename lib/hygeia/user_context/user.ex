defmodule Hygeia.UserContext.User do
  @moduledoc """
  Model for User
  """

  use Hygeia, :model

  alias Hygeia.CaseContext.Person
  alias Hygeia.CommunicationContext.Email
  alias Hygeia.NotificationContext.Notification
  alias Hygeia.TenantContext.Tenant
  alias Hygeia.UserContext.Grant
  alias Hygeia.UserContext.Grant.Role

  @role_map Grant.Role.__enum_map__()

  @derive {Phoenix.Param, key: :uuid}

  @type empty :: %__MODULE__{
          uuid: Ecto.UUID.t() | nil,
          email: String.t() | nil,
          display_name: String.t() | nil,
          iam_sub: String.t() | nil,
          grants: Ecto.Schema.has_many(Grant.t()) | nil,
          tenants: Ecto.Schema.has_many(Tenant.t()) | nil,
          notifications: Ecto.Schema.has_many(Notification.t()) | nil,
          emails: Ecto.Schema.has_many(Email.t()) | nil,
          inserted_at: DateTime.t() | nil,
          updated_at: DateTime.t() | nil
        }

  @type t :: %__MODULE__{
          uuid: Ecto.UUID.t(),
          email: String.t(),
          display_name: String.t(),
          iam_sub: String.t(),
          grants: Ecto.Schema.has_many(Grant.t()),
          tenants: Ecto.Schema.has_many(Tenant.t()),
          notifications: Ecto.Schema.has_many(Notification.t()),
          emails: Ecto.Schema.has_many(Email.t()),
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  schema "users" do
    field :display_name, :string
    field :email, :string
    field :iam_sub, :string

    has_many :grants, Grant, foreign_key: :user_uuid, on_replace: :delete
    has_many :tenants, through: [:grants, :tenant]
    has_many :notifications, Notification, foreign_key: :user_uuid, on_replace: :delete
    has_many :emails, Email, foreign_key: :user_uuid

    timestamps()
  end

  @spec changeset(user :: t | empty, attrs :: Hygeia.ecto_changeset_params()) :: Changeset.t()
  def changeset(user, %{grants: []} = attrs) do
    user
    |> cast(attrs, [:uuid, :email, :display_name, :iam_sub])
    |> cast_assoc(:grants)
    |> validate_required([:display_name, :iam_sub])
    |> unique_constraint(:iam_sub)
  end

  def changeset(user, attrs) do
    user
    |> cast(attrs, [:uuid, :email, :display_name, :iam_sub])
    |> cast_assoc(:grants)
    |> validate_required([:display_name, :iam_sub])
    |> unique_constraint(:iam_sub)
    |> handle_grants()
  end

  defp handle_grants(changeset) do
    changeset
    |> fetch_field!(:grants)
    |> case do
      [_ | _] ->
        changeset
        |> validate_required([:email])
        |> validate_email(:email)

      [] ->
        changeset
        |> put_change(:display_name, "anonymous")
        |> put_change(:email, nil)
    end
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

  @spec has_role?(user :: Person.t(), role :: Role.t(), tenant :: Tenant.t() | :any | String.t()) ::
          false
  def has_role?(%Person{}, _role, _tenant), do: false

  @spec anonymize_user_attrs_as_needed(attrs :: map) :: map
  def anonymize_user_attrs_as_needed(%{grants: []} = attrs),
    do:
      attrs
      |> Map.replace(:email, nil)
      |> Map.replace(:display_name, "anonymous")

  def anonymize_user_attrs_as_needed(attrs), do: attrs

  defimpl Hygeia.Authorization.Resource do
    alias Hygeia.CaseContext.Person
    alias Hygeia.UserContext.User

    @spec preload(resource :: User.t()) :: User.t()
    def preload(resource), do: resource

    @spec authorized?(
            resource :: User.t(),
            action :: :list | :details,
            user :: :anonymous | User.t() | Person.t(),
            meta :: %{atom() => term}
          ) :: boolean
    def authorized?(_resource_user, action, :anonymous, _meta)
        when action in [:list, :details],
        do: false

    def authorized?(_resource_user, action, %Person{}, _meta)
        when action in [:list, :details],
        do: false

    def authorized?(_resource_user, action, user, _meta)
        when action in [:list, :details, :versioning, :deleted_versioning],
        do:
          Enum.any?(
            [:viewer, :tracer, :super_user, :supervisor, :admin],
            &User.has_role?(user, &1, :any)
          )
  end
end
