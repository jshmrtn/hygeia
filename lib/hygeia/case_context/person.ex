defmodule Hygeia.CaseContext.Person do
  @moduledoc """
  Model for Person Schema
  """

  use Hygeia, :model

  alias Hygeia.CaseContext.Address
  alias Hygeia.CaseContext.Case
  alias Hygeia.CaseContext.ExternalReference
  alias Hygeia.CaseContext.Note
  alias Hygeia.CaseContext.Person.ContactMethod
  alias Hygeia.CaseContext.Person.Sex
  alias Hygeia.CaseContext.Person.VaccinationShot
  alias Hygeia.EctoType.NOGA
  alias Hygeia.OrganisationContext.Affiliation
  alias Hygeia.OrganisationContext.Organisation
  alias Hygeia.TenantContext.Tenant

  @derive {Phoenix.Param, key: :uuid}

  @type empty :: %__MODULE__{
          uuid: Ecto.UUID.t() | nil,
          human_readable_id: String.t() | nil,
          first_name: String.t() | nil,
          last_name: String.t() | nil,
          sex: Sex.t() | nil,
          birth_date: Date.t() | nil,
          address: Address.t() | nil,
          contact_methods: [ContactMethod.t()] | nil,
          external_references: [ExternalReference.t()] | nil,
          profession_category: NOGA.Code.t() | nil,
          profession_category_main: NOGA.Section.t() | nil,
          is_vaccinated: boolean() | nil,
          convalescent_externally: boolean() | nil,
          tenant_uuid: Ecto.UUID.t() | nil,
          tenant: Ecto.Schema.belongs_to(Tenant.t()) | nil,
          cases: Ecto.Schema.has_many(Case.t()) | nil,
          vaccination_shots: Ecto.Schema.has_many(VaccinationShot.t()) | nil,
          vaccination_shot_validities: Ecto.Schema.has_many(VaccinationShot.Validity.t()) | nil,
          affiliations: Ecto.Schema.has_many(Affiliation.t()) | nil,
          employee_affiliations: Ecto.Schema.has_many(Affiliation.t()) | nil,
          employers: Ecto.Schema.has_many(Organisation.t()) | nil,
          pinned_notes: Ecto.Schema.has_many(Note.t()) | nil,
          redacted: boolean() | nil,
          redaction_date: Date.t() | nil,
          reidentification_date: Date.t() | nil,
          inserted_at: DateTime.t() | nil,
          updated_at: DateTime.t() | nil
        }

  @type t :: %__MODULE__{
          uuid: Ecto.UUID.t(),
          human_readable_id: String.t(),
          first_name: String.t() | nil,
          last_name: String.t() | nil,
          sex: Sex.t() | nil,
          birth_date: Date.t() | nil,
          address: Address.t(),
          contact_methods: [ContactMethod.t()],
          external_references: [ExternalReference.t()],
          profession_category: NOGA.Code.t() | nil,
          profession_category_main: NOGA.Section.t() | nil,
          is_vaccinated: boolean() | nil,
          convalescent_externally: boolean(),
          tenant_uuid: Ecto.UUID.t(),
          tenant: Ecto.Schema.belongs_to(Tenant.t()),
          cases: Ecto.Schema.has_many(Case.t()),
          vaccination_shots: Ecto.Schema.has_many(VaccinationShot.t()),
          vaccination_shot_validities: Ecto.Schema.has_many(VaccinationShot.Validity.t()),
          affiliations: Ecto.Schema.has_many(Affiliation.t()),
          employee_affiliations: Ecto.Schema.has_many(Affiliation.t()),
          employers: Ecto.Schema.has_many(Organisation.t()),
          pinned_notes: Ecto.Schema.has_many(Note.t()),
          redacted: boolean(),
          redaction_date: Date.t() | nil,
          reidentification_date: Date.t() | nil,
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  @type changeset_options :: %{
          optional(:address_required) => boolean,
          optional(:vaccination) => boolean,
          optional(:vaccination_required) => boolean,
          optional(:initial_nil_jab_date_count) => integer
        }

  schema "people" do
    field :birth_date, :date
    field :first_name, :string
    field :human_readable_id, :string
    field :last_name, :string
    field :sex, Sex
    field :profession_category, NOGA.Code
    field :profession_category_main, NOGA.Section
    field :is_vaccinated, :boolean
    field :convalescent_externally, :boolean, default: false
    field :redacted, :boolean, default: false
    field :redaction_date, :date
    field :reidentification_date, :date

    embeds_one :address, Address, on_replace: :update
    embeds_many :contact_methods, ContactMethod, on_replace: :delete
    embeds_many :external_references, ExternalReference, on_replace: :delete

    has_many :vaccination_shots, VaccinationShot,
      foreign_key: :person_uuid,
      on_replace: :delete,
      preload_order: [asc: :date]

    has_many :vaccination_shot_validities, VaccinationShot.Validity, foreign_key: :person_uuid

    belongs_to :tenant, Tenant, references: :uuid, foreign_key: :tenant_uuid
    has_many :cases, Case
    has_many :affiliations, Affiliation, foreign_key: :person_uuid, on_replace: :delete

    has_many :employee_affiliations, Affiliation,
      foreign_key: :person_uuid,
      where: [kind: :employee]

    has_many :employers, through: [:employee_affiliations, :organisation]
    has_many :pinned_notes, through: [:cases, :pinned_notes]

    field :suspected_duplicates_uuid, {:array, :binary_id}, virtual: true, default: []

    timestamps()
  end

  @doc false
  @spec changeset(
          person :: t | empty | Changeset.t(t | empty),
          attrs :: Hygeia.ecto_changeset_params(),
          opts :: changeset_options
        ) :: Changeset.t()
  def changeset(person, attrs, opts \\ %{})

  def changeset(person, attrs, %{address_required: true} = opts) do
    person
    |> changeset(attrs, %{opts | address_required: false})
    |> cast_embed(:address, with: &Address.changeset(&1, &2, %{required: true}), required: true)
    |> validate_embed_required(:address, Address)
  end

  def changeset(person, attrs, %{vaccination_required: true} = opts) do
    person
    |> changeset(attrs, %{opts | vaccination_required: false})
    |> validate_required([:is_vaccinated])
  end

  def changeset(person, attrs, _opts) do
    person
    |> cast(attrs, [
      :uuid,
      :first_name,
      :last_name,
      :sex,
      :birth_date,
      :tenant_uuid,
      :profession_category_main,
      :profession_category,
      :is_vaccinated,
      :convalescent_externally,
      :redacted,
      :redaction_date,
      :reidentification_date
    ])
    |> fill_uuid
    |> fill_human_readable_id
    |> validate_required([
      :uuid,
      :human_readable_id,
      :tenant_uuid,
      :first_name,
      :convalescent_externally
    ])
    |> validate_past_date(:birth_date)
    |> validate_profession_category()
    |> cast_assoc(:affiliations)
    |> cast_embed(:external_references)
    |> cast_embed(:address)
    |> cast_embed(:contact_methods)
    |> cast_assoc(:vaccination_shots)
    |> validate_vaccination_shots()
    |> foreign_key_constraint(:tenant_uuid)
    |> detect_name_duplicates
    |> detect_duplicates(:mobile)
    |> detect_duplicates(:landline)
    |> detect_duplicates(:email)
  end

  defp validate_profession_category(changeset) do
    changeset
    |> fetch_change(:profession_category)
    |> case do
      :error ->
        changeset

      {:ok, nil} ->
        changeset

      {:ok, code} ->
        validate_inclusion(changeset, :profession_category_main, [NOGA.Code.section(code)])
    end
  end

  defp validate_vaccination_shots(changeset) do
    changeset
    |> fetch_change(:is_vaccinated)
    |> case do
      :error -> changeset
      {:ok, nil} -> changeset
      {:ok, true} -> cast_assoc(changeset, :vaccination_shots, required: true)
      {:ok, false} -> put_assoc(changeset, :vaccination_shots, [])
    end
  end

  defimpl Hygeia.Authorization.Resource do
    alias Hygeia.CaseContext.Person
    alias Hygeia.Repo
    alias Hygeia.TenantContext.Tenant
    alias Hygeia.UserContext.User

    @spec preload(resource :: Person.t()) :: Person.t()
    def preload(resource), do: Repo.preload(resource, :tenant)

    @spec authorized?(
            resource :: Person.t(),
            action :: :create | :details | :partial_details | :list | :update | :delete,
            user :: :anonymous | User.t() | Person.t(),
            meta :: %{atom() => term}
          ) :: boolean
    def authorized?(
          %Person{uuid: person_uuid},
          :partial_details,
          %Person{uuid: person_uuid},
          _meta
        ),
        do: true

    def authorized?(_person, action, :anonymous, _meta)
        when action in [:list, :create, :details, :partial_details, :update, :delete],
        do: false

    def authorized?(_person, action, %Person{}, _meta)
        when action in [:list, :create, :details, :partial_details, :update, :delete],
        do: false

    def authorized?(%Person{tenant: %Tenant{iam_domain: nil}}, action, user, _meta)
        when action in [:details, :partial_details, :versioning, :update, :delete],
        do:
          Enum.any?(
            [:super_user, :supervisor, :admin],
            &User.has_role?(user, &1, :any)
          )

    def authorized?(%Person{tenant: %Tenant{} = tenant}, action, user, _meta)
        when action in [:details, :partial_details, :versioning],
        do:
          Enum.any?(
            [:viewer, :tracer, :super_user, :supervisor, :admin],
            &User.has_role?(user, &1, tenant)
          )

    def authorized?(_module, :deleted_versioning, user, _meta),
      do: User.has_role?(user, :admin, :any)

    def authorized?(%Person{}, :update, user, %{tenant: tenant}),
      do:
        Enum.any?([:tracer, :super_user, :supervisor, :admin], &User.has_role?(user, &1, tenant))

    def authorized?(%Person{tenant_uuid: tenant_uuid}, :update, user, _meta),
      do:
        Enum.any?(
          [:tracer, :super_user, :supervisor, :admin],
          &User.has_role?(user, &1, tenant_uuid)
        )

    def authorized?(_module, :list, user, %{tenant: tenant}),
      do:
        Enum.any?(
          [:viewer, :tracer, :super_user, :supervisor, :admin],
          &User.has_role?(user, &1, tenant)
        )

    def authorized?(_module, :create, user, %{
          tenant: %Tenant{case_management_enabled: true}
        }),
        do:
          Enum.any?(
            [:tracer, :super_user, :supervisor, :admin],
            &User.has_role?(user, &1, :any)
          )

    def authorized?(_module, :create, _user, %{tenant: %Tenant{case_management_enabled: false}}),
      do: false

    def authorized?(_module, :create, user, %{tenant: :any}),
      do: Enum.any?([:tracer, :super_user, :supervisor, :admin], &User.has_role?(user, &1, :any))

    def authorized?(%Person{tenant_uuid: tenant_uuid}, :delete, user, _meta),
      do: Enum.any?([:supervisor, :super_user, :admin], &User.has_role?(user, &1, tenant_uuid))
  end
end
