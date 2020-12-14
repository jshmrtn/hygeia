defmodule Hygeia.CaseContext.Person do
  @moduledoc """
  Model for Person Schema
  """

  use Hygeia, :model

  import EctoEnum

  alias Hygeia.CaseContext.Address
  alias Hygeia.CaseContext.Case
  alias Hygeia.CaseContext.Case.ContactMethod
  alias Hygeia.CaseContext.Employer
  alias Hygeia.CaseContext.ExternalReference
  alias Hygeia.CaseContext.Profession
  alias Hygeia.OrganisationContext.Position
  alias Hygeia.TenantContext.Tenant

  defenum Sex, :sex, ["male", "female", "other"]

  @derive {Phoenix.Param, key: :uuid}

  @type empty :: %__MODULE__{
          uuid: String.t() | nil,
          human_readable_id: String.t() | nil,
          first_name: String.t() | nil,
          last_name: String.t() | nil,
          sex: Sex.t() | nil,
          birth_date: Date.t() | nil,
          address: Address.t() | nil,
          contact_methods: [ContactMethod.t()] | nil,
          external_references: [ExternalReference.t()] | nil,
          employers: [Employer.t()] | nil,
          profession_uuid: String.t() | nil,
          profession: Ecto.Schema.belongs_to(Profession.t()) | nil,
          tenant_uuid: String.t() | nil,
          tenant: Ecto.Schema.belongs_to(Tenant.t()) | nil,
          cases: Ecto.Schema.has_many(Case.t()) | nil,
          positions: Ecto.Schema.has_many(Position.t()) | nil,
          inserted_at: NaiveDateTime.t() | nil,
          updated_at: NaiveDateTime.t() | nil
        }

  @type t :: %__MODULE__{
          uuid: String.t(),
          human_readable_id: String.t(),
          first_name: String.t() | nil,
          last_name: String.t() | nil,
          sex: Sex.t() | nil,
          birth_date: Date.t() | nil,
          address: Address.t(),
          contact_methods: [ContactMethod.t()],
          external_references: [ExternalReference.t()],
          employers: [Employer.t()],
          profession_uuid: String.t() | nil,
          profession: Ecto.Schema.belongs_to(Profession.t()),
          tenant_uuid: String.t(),
          tenant: Ecto.Schema.belongs_to(Tenant.t()),
          cases: Ecto.Schema.has_many(Case.t()),
          positions: Ecto.Schema.has_many(Position.t()),
          inserted_at: NaiveDateTime.t(),
          updated_at: NaiveDateTime.t()
        }

  schema "people" do
    field :birth_date, :date
    field :first_name, :string
    field :human_readable_id, :string
    field :last_name, :string
    field :sex, Sex

    embeds_one :address, Address, on_replace: :update
    embeds_many :contact_methods, ContactMethod, on_replace: :delete
    embeds_many :external_references, ExternalReference, on_replace: :delete
    embeds_many :employers, Employer, on_replace: :delete

    belongs_to :profession, Profession, references: :uuid, foreign_key: :profession_uuid
    belongs_to :tenant, Tenant, references: :uuid, foreign_key: :tenant_uuid
    has_many :cases, Case
    has_many :positions, Position, foreign_key: :person_uuid

    field :suspected_duplicates_uuid, {:array, :binary_id}, virtual: true, default: []

    timestamps()
  end

  @doc false
  @spec changeset(person :: t | empty, attrs :: Hygeia.ecto_changeset_params()) :: Changeset.t()
  def changeset(person, attrs) do
    person
    |> cast(attrs, [
      :uuid,
      :first_name,
      :last_name,
      :sex,
      :birth_date,
      :tenant_uuid,
      :profession_uuid
    ])
    |> fill_uuid
    |> fill_human_readable_id
    |> validate_required([:uuid, :human_readable_id, :tenant_uuid, :first_name])
    |> cast_embed(:external_references)
    |> cast_embed(:address)
    |> cast_embed(:contact_methods)
    |> cast_embed(:employers)
    |> foreign_key_constraint(:tenant_uuid)
    |> foreign_key_constraint(:profession_uuid)
    |> detect_name_duplicates
    |> detect_duplicates(:mobile)
    |> detect_duplicates(:landline)
    |> detect_duplicates(:email)
  end

  defimpl Hygeia.Authorization.Resource do
    alias Hygeia.CaseContext.Person
    alias Hygeia.UserContext.User

    @spec authorized?(
            resource :: Person.t(),
            action :: :create | :details | :list | :update | :delete,
            user :: :anonymous | User.t(),
            meta :: %{atom() => term}
          ) :: boolean
    def authorized?(_person, action, :anonymous, _meta)
        when action in [:list, :create, :details, :update, :delete],
        do: false

    def authorized?(_person, action, %User{roles: roles}, _meta)
        when action in [:list, :create, :details, :update],
        do: :tracer in roles or :supervisor in roles or :admin in roles

    def authorized?(_person, action, %User{roles: roles}, _meta)
        when action in [:delete],
        do: :supervisor in roles or :admin in roles
  end
end
