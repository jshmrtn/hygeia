defmodule Hygeia.PoliticalTerritoryContext.PoliticalTerritory do
  @moduledoc """
  Model for Political Territories.
  """

  use Hygeia, :model

  alias Hygeia.EctoType.Country

  @derive {Phoenix.Param, key: :uuid}

  @type empty :: %__MODULE__{
          uuid: Ecto.UUID.t() | nil,
          country: Country.t() | nil,
          risk_related: boolean() | nil
        }

  @type t :: %__MODULE__{
          uuid: Ecto.UUID.t(),
          country: Country.t(),
          risk_related: boolean()
        }

  schema "political_territories" do
    field :country, Country
    field :risk_related, :boolean

    timestamps()
  end

  @doc false
  @spec changeset(political_territory :: t | empty, attrs :: Hygeia.ecto_changeset_params()) ::
          Changeset.t()
  def changeset(political_territory, attrs) do
    political_territory
    |> cast(attrs, [:country, :risk_related])
    |> validate_required([:country, :risk_related])
    |> unique_constraint(:country)
  end

  defimpl Hygeia.Authorization.Resource do
    alias Hygeia.CaseContext.Person
    alias Hygeia.PoliticalTerritoryContext.PoliticalTerritory
    alias Hygeia.UserContext.User

    @spec preload(resource :: PoliticalTerritory.t()) :: PoliticalTerritory.t()
    def preload(resource), do: resource

    @spec authorized?(
            resource :: PoliticalTerritory.t(),
            action :: :create | :list | :details | :update | :delete,
            user :: :anonymous | User.t() | Person.t(),
            meta :: %{atom() => term}
          ) :: boolean
    def authorized?(_mutation, action, :anonymous, _meta)
        when action in [:list, :create, :details, :update, :delete],
        do: false

    def authorized?(_mutation, action, %Person{}, _meta)
        when action in [:list, :create, :details, :update, :delete],
        do: false

    def authorized?(_mutation, action, user, _meta)
        when action in [:details, :list, :versioning, :deleted_versioning],
        do:
          Enum.any?(
            [:viewer, :tracer, :super_user, :supervisor, :admin],
            &User.has_role?(user, &1, :any)
          )

    def authorized?(_mutation, action, user, _meta)
        when action in [:create, :update, :delete],
        do: Enum.any?([:admin], &User.has_role?(user, &1, :any))
  end
end
