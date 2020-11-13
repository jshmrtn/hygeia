defmodule Hygeia.TenantContext.Tenant do
  @moduledoc """
  Model for Tenants
  """

  use Hygeia, :model

  alias Hygeia.CaseContext.Case
  alias Hygeia.CaseContext.Person

  @derive {Phoenix.Param, key: :uuid}

  @type empty :: %__MODULE__{
          uuid: String.t() | nil,
          name: String.t() | nil,
          public_statistics: boolean | nil,
          people: Ecto.Schema.has_many(Person.t()) | nil,
          cases: Ecto.Schema.has_many(Case.t()) | nil,
          inserted_at: NaiveDateTime.t() | nil,
          updated_at: NaiveDateTime.t() | nil
        }

  @type t :: %__MODULE__{
          uuid: String.t(),
          name: String.t(),
          public_statistics: boolean,
          people: Ecto.Schema.has_many(Person.t()),
          cases: Ecto.Schema.has_many(Case.t()),
          inserted_at: NaiveDateTime.t(),
          updated_at: NaiveDateTime.t()
        }

  schema "tenants" do
    field :name, :string
    field :public_statistics, :boolean, default: false

    has_many :people, Person
    has_many :cases, Case

    timestamps()
  end

  @doc false
  @spec changeset(tenant :: t | empty, attrs :: Hygeia.ecto_changeset_params()) :: Changeset.t()
  def changeset(tenant, attrs) do
    tenant
    |> cast(attrs, [:name, :public_statistics])
    |> validate_required([:name, :public_statistics])
  end

  defimpl Hygeia.Authorization.Resource do
    alias Hygeia.TenantContext.Tenant
    alias Hygeia.UserContext.User

    @spec authorized?(
            resource :: Tenant.t(),
            action :: :create | :details | :list | :update | :delete,
            user :: :anonymous | User.t(),
            meta :: %{atom() => term}
          ) :: boolean
    def authorized?(_tenant, :list, _user, _meta), do: true

    def authorized?(_tenant, action, :anonymous, _meta)
        when action in [:create, :details, :update, :delete],
        do: false

    def authorized?(
          %Tenant{public_statistics: public_statistics} = _tenant,
          :statistics,
          :anonymous,
          _meta
        ),
        do: public_statistics

    def authorized?(_tenant, :statistics, %User{}, _meta), do: true

    def authorized?(_tenant, action, %User{roles: roles}, _meta)
        when action in [:create, :details, :update, :delete],
        do: :admin in roles
  end
end
