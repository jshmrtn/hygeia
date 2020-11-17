defmodule Hygeia.CaseContext.InfectionPlaceType do
  @moduledoc """
  Model for Infection Place Type Schema
  """

  use Hygeia, :model

  @derive {Phoenix.Param, key: :uuid}

  @type empty :: %__MODULE__{
          uuid: String.t() | nil,
          name: String.t() | nil,
          inserted_at: NaiveDateTime.t() | nil,
          updated_at: NaiveDateTime.t() | nil
        }

  @type t :: %__MODULE__{
          uuid: String.t(),
          name: String.t(),
          inserted_at: NaiveDateTime.t(),
          updated_at: NaiveDateTime.t()
        }

  schema "infection_place_types" do
    field :name, :string

    timestamps()
  end

  @spec changeset(infection_place_type :: t | empty, attrs :: Hygeia.ecto_changeset_params()) ::
          Changeset.t()
  def changeset(infection_place_type, attrs) do
    infection_place_type
    |> cast(attrs, [:name])
    |> validate_required([:name])
  end

  defimpl Hygeia.Authorization.Resource do
    alias Hygeia.CaseContext.InfectionPlaceType
    alias Hygeia.UserContext.User

    @spec authorized?(
            resource :: InfectionPlaceType.t(),
            action :: :create | :list | :details | :update | :delete,
            user :: :anonymous | User.t(),
            meta :: %{atom() => term}
          ) :: boolean
    def authorized?(_infection_place_type, action, _user, _meta)
        when action in [:list, :details],
        do: true

    def authorized?(_infection_place_type, action, :anonymous, _meta)
        when action in [:create, :update, :delete],
        do: false

    def authorized?(_infection_place_type, action, %User{roles: roles}, _meta)
        when action in [:create, :update, :delete],
        do: :admin in roles
  end
end
