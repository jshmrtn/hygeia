defmodule Hygeia.UserContext.User do
  @moduledoc """
  Model for User
  """

  use Hygeia, :model

  import EctoEnum

  defenum Role, :user_role, ["tracer", "supervisor", "admin", "webmaster", "statistics_viewer"]
  @role_map Role.__enum_map__()

  @derive {Phoenix.Param, key: :uuid}

  @type empty :: %__MODULE__{
          uuid: String.t() | nil,
          email: String.t() | nil,
          display_name: String.t() | nil,
          iam_sub: String.t() | nil,
          roles: [Role.t()] | nil,
          inserted_at: NaiveDateTime.t() | nil,
          updated_at: NaiveDateTime.t() | nil
        }

  @type t :: %__MODULE__{
          uuid: String.t(),
          email: String.t(),
          display_name: String.t(),
          iam_sub: String.t(),
          roles: [Role.t()],
          inserted_at: NaiveDateTime.t(),
          updated_at: NaiveDateTime.t()
        }

  schema "users" do
    field :display_name, :string
    field :email, :string
    field :iam_sub, :string
    # TODO: Replace with Relation to Tenant to scope roles to tenant
    field :roles, {:array, Role}, default: []

    timestamps()
  end

  @doc false
  @spec changeset(user :: t | empty, attrs :: Hygeia.ecto_changeset_params()) :: Changeset.t()
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:email, :display_name, :iam_sub, :roles])
    |> validate_required([:email, :display_name, :iam_sub, :roles])
    |> unique_constraint(:iam_sub)
    |> validate_email(:email)
  end

  @spec has_role?(user :: t, role :: Role.t()) :: boolean
  def has_role?(%__MODULE__{roles: roles}, role) when role in @role_map, do: role in roles

  @spec has_role?(user :: :anonymous, role :: Role.t()) :: false
  def has_role?(:anonymous, _role), do: false

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

    def authorized?(_resource_user, action, %User{roles: []}, _meta)
        when action in [:list, :details],
        do: false

    def authorized?(_resource_user, action, %User{roles: [_ | _]}, _meta)
        when action in [:list, :details],
        do: true
  end
end
