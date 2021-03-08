defmodule Hygeia.OrganisationContext.Affiliation do
  @moduledoc """
  Model for Affiliation
  """

  use Hygeia, :model

  import HygeiaGettext

  alias Hygeia.CaseContext.Person
  alias Hygeia.OrganisationContext.Affiliation.Kind
  alias Hygeia.OrganisationContext.Division
  alias Hygeia.OrganisationContext.Organisation
  alias Hygeia.TenantContext.Tenant

  @type empty :: %__MODULE__{
          kind: Kind.t() | nil,
          kind_other: String.t() | nil,
          person_uuid: String.t() | nil,
          person: Ecto.Schema.belongs_to(Person.t()) | nil,
          organisation_uuid: String.t() | nil,
          organisation: Ecto.Schema.belongs_to(Organisation.t()) | nil,
          division_uuid: String.t() | nil,
          division: Ecto.Schema.belongs_to(Division.t()) | nil,
          tenant: Ecto.Schema.has_one(Tenant.t()) | nil,
          comment: String.t() | nil,
          inserted_at: NaiveDateTime.t() | nil,
          updated_at: NaiveDateTime.t() | nil
        }

  @type t :: %__MODULE__{
          kind: Kind.t(),
          kind_other: String.t() | nil,
          person_uuid: String.t(),
          person: Ecto.Schema.belongs_to(Person.t()),
          organisation_uuid: String.t() | nil,
          organisation: Ecto.Schema.belongs_to(Organisation.t()) | nil,
          division_uuid: String.t() | nil,
          division: Ecto.Schema.belongs_to(Division.t()) | nil,
          tenant: Ecto.Schema.has_one(Tenant.t()),
          comment: String.t() | nil,
          inserted_at: NaiveDateTime.t(),
          updated_at: NaiveDateTime.t()
        }

  schema "affiliations" do
    field :kind, Kind
    field :kind_other, :string
    field :comment, :string

    belongs_to :person, Person, references: :uuid, foreign_key: :person_uuid
    belongs_to :organisation, Organisation, references: :uuid, foreign_key: :organisation_uuid
    belongs_to :division, Division, references: :uuid, foreign_key: :division_uuid
    has_one :tenant, through: [:person, :tenant]

    timestamps()
  end

  @spec changeset(affiliation :: empty | t, attrs :: Hygeia.ecto_changeset_params()) ::
          Ecto.Changeset.t(empty | t)
  def changeset(affiliation, attrs),
    do:
      affiliation
      |> cast(attrs, [
        :uuid,
        :kind,
        :kind_other,
        :person_uuid,
        :organisation_uuid,
        :division_uuid,
        :comment
      ])
      |> fill_uuid()
      |> assoc_constraint(:person)
      |> assoc_constraint(:organisation)
      |> assoc_constraint(:division)
      |> validate_kind_other()
      |> validate_organisation_or_comment()

  defp validate_organisation_or_comment(changeset) do
    with nil <- fetch_field!(changeset, :organisation_uuid),
         nil <- fetch_field!(changeset, :comment) do
      add_error(changeset, :comment, gettext("either organisation or comment must be filled"))
    else
      _other -> changeset
    end
  end

  defp validate_kind_other(changeset) do
    changeset
    |> fetch_field!(:kind)
    |> case do
      :other -> validate_required(changeset, [:kind_other])
      _defined -> put_change(changeset, :kind_other, nil)
    end
  end

  defimpl Hygeia.Authorization.Resource do
    alias Hygeia.OrganisationContext.Affiliation
    alias Hygeia.Repo
    alias Hygeia.UserContext.User

    @spec preload(resource :: Affiliation.t()) :: Affiliation.t()
    def preload(resource), do: Repo.preload(resource, tenant: [])

    @spec authorized?(
            resource :: Affiliation.t(),
            action :: :list | :versioning | :deleted_versioning,
            user :: :anonymous | User.t(),
            meta :: %{atom() => term}
          ) :: boolean
    def authorized?(_affiliation, _action, :anonymous, _meta), do: false

    def authorized?(_division, action, user, _meta)
        when action in [:list, :versioning, :deleted_versioning],
        do:
          Enum.any?(
            [:viewer, :tracer, :super_user, :supervisor, :admin],
            &User.has_role?(user, &1, :any)
          )
  end
end
