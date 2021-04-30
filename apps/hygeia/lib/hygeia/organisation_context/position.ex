defmodule Hygeia.OrganisationContext.Position do
  @moduledoc """
  Model for Positions
  """

  use Hygeia, :model

  alias Hygeia.CaseContext.Person
  alias Hygeia.OrganisationContext.Organisation

  @derive {Phoenix.Param, key: :uuid}

  @type empty :: %__MODULE__{
          uuid: Ecto.UUID.t() | nil,
          position: String.t() | nil,
          person_uuid: Ecto.UUID.t() | nil,
          person: Ecto.Schema.belongs_to(Person.t()) | nil,
          organisation_uuid: Ecto.UUID.t() | nil,
          organisation: Ecto.Schema.belongs_to(Organisation.t()) | nil,
          inserted_at: NaiveDateTime.t() | nil,
          updated_at: NaiveDateTime.t() | nil
        }
  @type t :: %__MODULE__{
          uuid: Ecto.UUID.t(),
          position: String.t(),
          person_uuid: Ecto.UUID.t(),
          person: Ecto.Schema.belongs_to(Person.t()),
          organisation_uuid: Ecto.UUID.t(),
          organisation: Ecto.Schema.belongs_to(Organisation.t()),
          inserted_at: NaiveDateTime.t(),
          updated_at: NaiveDateTime.t()
        }

  schema "positions" do
    field :position, :string

    belongs_to :person, Person, references: :uuid, foreign_key: :person_uuid
    belongs_to :organisation, Organisation, references: :uuid, foreign_key: :organisation_uuid

    timestamps()
  end

  @doc false
  @spec changeset(position :: empty | t, attrs :: Hygeia.ecto_changeset_params()) ::
          Ecto.Changeset.t()
  def changeset(position, attrs) do
    position
    |> cast(attrs, [:uuid, :position, :person_uuid, :organisation_uuid])
    |> fill_uuid
    |> validate_required([:position, :person_uuid])
  end

  defimpl Hygeia.Authorization.Resource do
    alias Hygeia.CaseContext.Person
    alias Hygeia.OrganisationContext.Position
    alias Hygeia.UserContext.User

    @spec preload(resource :: Position.t()) :: Position.t()
    def preload(resource), do: resource

    @spec authorized?(
            resource :: Position.t(),
            action :: :create | :list | :delete,
            user :: :anonymous | User.t() | Person.t(),
            meta :: %{atom() => term}
          ) :: boolean
    def authorized?(_position, action, :anonymous, _meta)
        when action in [:list, :create, :delete],
        do: false

    def authorized?(_position, action, %Person{}, _meta)
        when action in [:list, :create, :delete],
        do: false

    def authorized?(_position, :list, user, _meta),
      do:
        Enum.any?(
          [:viewer, :tracer, :super_user, :supervisor, :admin],
          &User.has_role?(user, &1, :any)
        )

    def authorized?(_position, action, user, _meta)
        when action in [:create, :delete],
        do:
          Enum.any?([:tracer, :super_user, :supervisor, :admin], &User.has_role?(user, &1, :any))
  end
end
