defmodule Hygeia.OrganisationContext.Affiliation do
  @moduledoc """
  Model for Affiliation
  """

  use Hygeia, :model

  import HygeiaGettext

  alias Hygeia.CaseContext.Entity
  alias Hygeia.CaseContext.Person
  alias Hygeia.OrganisationContext.Affiliation.Kind
  alias Hygeia.OrganisationContext.Division
  alias Hygeia.OrganisationContext.Organisation
  alias Hygeia.OrganisationContext.Visit
  alias Hygeia.TenantContext.Tenant

  @type empty :: %__MODULE__{
          kind: Kind.t() | nil,
          kind_other: String.t() | nil,
          person_uuid: Ecto.UUID.t() | nil,
          person: Ecto.Schema.belongs_to(Person.t()) | nil,
          organisation_uuid: Ecto.UUID.t() | nil,
          organisation: Ecto.Schema.belongs_to(Organisation.t()) | nil,
          unknown_organisation: Entity.t() | nil,
          related_visit_uuid: Ecto.UUID.t() | nil,
          related_visit: Ecto.Schema.belongs_to(Visit.t()) | nil,
          division_uuid: Ecto.UUID.t() | nil,
          division: Ecto.Schema.belongs_to(Division.t()) | nil,
          unknown_division: Entity.t() | nil,
          tenant: Ecto.Schema.has_one(Tenant.t()) | nil,
          comment: String.t() | nil,
          inserted_at: DateTime.t() | nil,
          updated_at: DateTime.t() | nil
        }

  @type t :: %__MODULE__{
          kind: Kind.t(),
          kind_other: String.t() | nil,
          person_uuid: Ecto.UUID.t(),
          person: Ecto.Schema.belongs_to(Person.t()),
          organisation_uuid: Ecto.UUID.t() | nil,
          organisation: Ecto.Schema.belongs_to(Organisation.t()) | nil,
          unknown_organisation: Entity.t() | nil,
          related_visit_uuid: Ecto.UUID.t() | nil,
          related_visit: Ecto.Schema.belongs_to(Visit.t()) | nil,
          division_uuid: Ecto.UUID.t() | nil,
          division: Ecto.Schema.belongs_to(Division.t()) | nil,
          unknown_division: Entity.t() | nil,
          tenant: Ecto.Schema.has_one(Tenant.t()),
          comment: String.t() | nil,
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  schema "affiliations" do
    field :kind, Kind
    field :kind_other, :string
    field :comment, :string

    belongs_to :person, Person, references: :uuid, foreign_key: :person_uuid
    belongs_to :organisation, Organisation, references: :uuid, foreign_key: :organisation_uuid

    embeds_one :unknown_organisation, Entity, on_replace: :delete

    belongs_to :related_visit, Visit,
      references: :uuid,
      foreign_key: :related_visit_uuid

    belongs_to :division, Division, references: :uuid, foreign_key: :division_uuid
    has_one :tenant, through: [:person, :tenant]

    embeds_one :unknown_division, Entity, on_replace: :delete

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
      |> cast_embed(:unknown_organisation)
      |> validate_kind_other()
      |> validate_organisation_or_comment()
      |> validate_organisation()
      |> validate_division()
      |> check_constraint(:organisation_uuid, name: :organisation_info_required)

  defp validate_organisation_or_comment(changeset) do
    with nil <- fetch_field!(changeset, :organisation_uuid),
         nil <- fetch_field!(changeset, :unknown_organisation),
         nil <- fetch_field!(changeset, :comment) do
      add_error(
        changeset,
        :comment,
        gettext(
          "either an existing organisation, an unknown organisation or a comment must be filled"
        )
      )
    else
      _other -> changeset
    end
  end

  defp validate_organisation(changeset) do
    changeset
    |> fetch_field!(:organisation_uuid)
    |> case do
      nil ->
        cast_embed(changeset, :unknown_organisation)

      _else ->
        put_embed(changeset, :unknown_organisation, nil)
    end
  end

  defp validate_division(changeset) do
    changeset
    |> fetch_field!(:division_uuid)
    |> case do
      nil -> cast_embed(changeset, :unknown_division)
      _else -> put_embed(changeset, :unknown_division, nil)
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

  @spec kind_name(affiliation :: t()) :: String.t() | nil
  def kind_name(%__MODULE__{kind: nil}), do: nil

  def kind_name(%__MODULE__{kind: :other, kind_other: kind_other}),
    do: "#{Kind.translate(:other)} / #{kind_other}"

  def kind_name(%__MODULE__{kind: kind}), do: Kind.translate(kind)

  defimpl Hygeia.Authorization.Resource do
    alias Hygeia.CaseContext.Person
    alias Hygeia.OrganisationContext.Affiliation
    alias Hygeia.Repo
    alias Hygeia.UserContext.User

    @spec preload(resource :: Affiliation.t()) :: Affiliation.t()
    def preload(resource), do: Repo.preload(resource, tenant: [])

    @spec authorized?(
            resource :: Affiliation.t(),
            action :: :list | :versioning | :deleted_versioning,
            user :: :anonymous | User.t() | Person.t(),
            meta :: %{atom() => term}
          ) :: boolean
    def authorized?(_affiliation, _action, :anonymous, _meta), do: false
    def authorized?(_affiliation, _action, %Person{}, _meta), do: false

    def authorized?(_division, action, user, _meta)
        when action in [:list, :versioning, :deleted_versioning],
        do:
          Enum.any?(
            [:viewer, :tracer, :super_user, :supervisor, :admin],
            &User.has_role?(user, &1, :any)
          )
  end
end
