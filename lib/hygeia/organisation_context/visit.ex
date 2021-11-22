defmodule Hygeia.OrganisationContext.Visit do
  @moduledoc """
  Model for Visits
  """

  use Hygeia, :model

  alias Hygeia.CaseContext.Entity
  alias Hygeia.CaseContext.Person
  alias Hygeia.OrganisationContext.Affiliation
  alias Hygeia.OrganisationContext.Division
  alias Hygeia.OrganisationContext.Organisation
  alias Hygeia.OrganisationContext.Visit.Reason

  @type empty :: %__MODULE__{
          uuid: Ecto.UUID.t() | nil,
          reason: Reason.t() | nil,
          other_reason: String.t() | nil,
          last_visit_at: Date.t() | nil,
          person_uuid: Ecto.UUID.t() | nil,
          person: Ecto.Schema.belongs_to(Person.t()) | nil,
          organisation_uuid: Ecto.UUID.t() | nil,
          organisation: Ecto.Schema.belongs_to(Organisation.t()) | nil,
          unknown_organisation: Entity.t() | nil,
          division_uuid: Ecto.UUID.t() | nil,
          division: Ecto.Schema.belongs_to(Division.t()) | nil,
          unknown_division: Entity.t() | nil,
          affiliation: Ecto.Schema.has_one(Affiliation.t()),
          inserted_at: DateTime.t() | nil,
          updated_at: DateTime.t() | nil
        }

  @type t :: %__MODULE__{
          uuid: Ecto.UUID.t(),
          reason: Reason.t() | nil,
          other_reason: String.t() | nil,
          last_visit_at: Date.t() | nil,
          person_uuid: Ecto.UUID.t() | nil,
          person: Ecto.Schema.belongs_to(Person.t()) | nil,
          organisation_uuid: Ecto.UUID.t() | nil,
          organisation: Ecto.Schema.belongs_to(Organisation.t()) | nil,
          unknown_organisation: Entity.t() | nil,
          division_uuid: Ecto.UUID.t() | nil,
          division: Ecto.Schema.belongs_to(Division.t()) | nil,
          unknown_division: Entity.t() | nil,
          affiliation: Ecto.Schema.has_one(Affiliation.t()),
          inserted_at: DateTime.t() | nil,
          updated_at: DateTime.t() | nil
        }

  schema "visits" do
    field :reason, Reason
    field :other_reason, :string
    field :last_visit_at, :date

    belongs_to :person, Person, references: :uuid, foreign_key: :person_uuid

    belongs_to :organisation, Organisation,
      foreign_key: :organisation_uuid,
      references: :uuid

    embeds_one :unknown_organisation, Entity, on_replace: :delete

    belongs_to :division, Division,
      foreign_key: :division_uuid,
      references: :uuid

    embeds_one :unknown_division, Entity, on_replace: :delete

    has_one :affiliation, Affiliation,
      foreign_key: :related_visit_uuid,
      on_replace: :update,
      on_delete: :delete_all

    timestamps()
  end

  @spec changeset(visit :: t | empty, attrs :: Hygeia.ecto_changeset_params()) ::
          Changeset.t()
  @doc false
  def changeset(visit, attrs) do
    visit
    |> cast(attrs, [
      :uuid,
      :reason,
      :other_reason,
      :last_visit_at,
      :person_uuid,
      :organisation_uuid,
      :division_uuid
    ])
    |> assoc_constraint(:person)
    |> validate_required([:reason, :last_visit_at])
    |> validate_other_reason()
    |> validate_organisation()
    |> validate_division()
    |> validate_organisation_required()
  end

  defp validate_other_reason(changeset) do
    changeset
    |> fetch_field!(:reason)
    |> case do
      :other -> validate_required(changeset, [:other_reason])
      _defined -> put_change(changeset, :other_reason, nil)
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

  defp validate_organisation_required(changeset) do
    if is_nil(fetch_field!(changeset, :organisation_uuid)) and
         is_nil(fetch_field!(changeset, :unknown_organisation)) do
      validate_required(changeset, :organisation_uuid)
    else
      changeset
    end
  end

  defimpl Hygeia.Authorization.Resource do
    alias Hygeia.CaseContext.Person
    alias Hygeia.OrganisationContext.Visit
    alias Hygeia.Repo
    alias Hygeia.UserContext.User

    @spec preload(resource :: Visit.t()) :: Visit.t()
    def preload(resource), do: Repo.preload(resource, person: [])

    @spec authorized?(
            resource :: Visit.t(),
            action :: :create | :details | :update | :delete,
            user :: :anonymous | User.t() | Person.t(),
            meta :: %{atom() => term}
          ) :: boolean
    def authorized?(
          _visit,
          :create,
          user,
          %{person: %Person{tenant_uuid: tenant_uuid}}
        ),
        do:
          Enum.any?(
            [:tracer, :super_user, :supervisor, :admin],
            &User.has_role?(user, &1, tenant_uuid)
          )

    def authorized?(
          _visit,
          :list,
          user,
          %{person: %Person{tenant_uuid: tenant_uuid}}
        ),
        do:
          Enum.any?(
            [:tracer, :super_user, :supervisor, :admin, :viewer],
            &User.has_role?(user, &1, tenant_uuid)
          )

    def authorized?(
          %Visit{person: %Person{tenant_uuid: tenant_uuid}},
          :details,
          user,
          _meta
        ),
        do:
          Enum.any?(
            [:tracer, :super_user, :supervisor, :admin, :viewer],
            &User.has_role?(user, &1, tenant_uuid)
          )

    def authorized?(
          %Visit{person: %Person{tenant_uuid: tenant_uuid}},
          action,
          user,
          _meta
        )
        when action in [:update, :delete] do
      Enum.any?(
        [:tracer, :super_user, :supervisor, :admin],
        &User.has_role?(user, &1, tenant_uuid)
      )
    end

    def authorized?(_visit, _action, _user, _meta), do: false
  end
end
