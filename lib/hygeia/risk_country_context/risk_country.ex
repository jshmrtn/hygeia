defmodule Hygeia.RiskCountryContext.RiskCountry do
  @moduledoc """
  Model for Risk Countries.
  """

  use Hygeia, :model

  alias Hygeia.EctoType.Country

  @derive {Phoenix.Param, key: :uuid}

  @type empty :: %__MODULE__{
          uuid: Ecto.UUID.t() | nil,
          country: Country.t() | nil
        }

  @type t :: %__MODULE__{
          uuid: Ecto.UUID.t(),
          country: Country.t()
        }

  schema "risk_countries" do
    field :country, Country
  end

  @doc false
  @spec changeset(risk_country :: t | empty, attrs :: Hygeia.ecto_changeset_params()) ::
          Changeset.t()
  def changeset(risk_country, attrs) do
    risk_country
    |> cast(attrs, [:country])
    |> validate_required([:country])
    |> unique_constraint(:country)
  end

  defimpl Hygeia.Authorization.Resource do
    alias Hygeia.CaseContext.Person
    alias Hygeia.RiskCountryContext.RiskCountry
    alias Hygeia.UserContext.User

    @spec preload(resource :: RiskCountry.t()) :: RiskCountry.t()
    def preload(resource), do: resource

    @spec authorized?(
            resource :: RiskCountry.t(),
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
