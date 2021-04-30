defmodule Hygeia.OrganisationContext.Division do
  @moduledoc """
  Model for Division
  """

  use Hygeia, :model

  alias Hygeia.CaseContext.Address
  alias Hygeia.OrganisationContext.Affiliation
  alias Hygeia.OrganisationContext.Organisation

  @derive {Phoenix.Param, key: :uuid}

  @type empty :: %__MODULE__{
          title: String.t() | nil,
          description: String.t() | nil,
          organisation_uuid: Ecto.UUID.t() | nil,
          organisation: Ecto.Schema.belongs_to(Organisation.t()) | nil,
          affiliations: Ecto.Schema.belongs_to(Affiliation.t()) | nil,
          shares_address: boolean() | nil,
          address: Address.t() | nil,
          inserted_at: NaiveDateTime.t() | nil,
          updated_at: NaiveDateTime.t() | nil
        }

  @type t :: %__MODULE__{
          title: String.t(),
          description: String.t() | nil,
          organisation_uuid: Ecto.UUID.t(),
          organisation: Ecto.Schema.belongs_to(Organisation.t()),
          affiliations: Ecto.Schema.belongs_to(Affiliation.t()),
          shares_address: boolean(),
          address: Address.t() | nil,
          inserted_at: NaiveDateTime.t(),
          updated_at: NaiveDateTime.t()
        }

  schema "divisions" do
    field :description, :string
    field :title, :string
    field :shares_address, :boolean, default: true

    embeds_one :address, Address, on_replace: :update

    belongs_to :organisation, Organisation, references: :uuid, foreign_key: :organisation_uuid
    has_many :affiliations, Affiliation, foreign_key: :division_uuid, on_replace: :delete

    timestamps()
  end

  @spec changeset(division :: t | empty, attrs :: Hygeia.ecto_changeset_params()) ::
          Ecto.Changeset.t(t())
  def changeset(division, attrs),
    do:
      division
      |> cast(attrs, [:title, :description, :organisation_uuid, :shares_address])
      |> validate_required([:title])
      |> assoc_constraint(:organisation)
      |> validate_shares_address()

  defp validate_shares_address(changeset) do
    changeset
    |> fetch_field!(:shares_address)
    |> case do
      false -> cast_embed(changeset, :address, required: true)
      true -> put_embed(changeset, :address, nil)
    end
  end

  defimpl Hygeia.Authorization.Resource do
    alias Hygeia.CaseContext.Person
    alias Hygeia.OrganisationContext
    alias Hygeia.OrganisationContext.Division
    alias Hygeia.UserContext.User

    @spec preload(resource :: Division.t()) :: Division.t()
    def preload(resource), do: resource

    @spec authorized?(
            resource :: Division.t(),
            action :: :create | :list | :details | :update | :delete,
            user :: :anonymous | User.t() | Person.t(),
            meta :: %{atom() => term}
          ) :: boolean
    def authorized?(_division, action, :anonymous, _meta)
        when action in [:list, :create, :details, :update, :delete],
        do: false

    def authorized?(_division, action, %Person{}, _meta)
        when action in [:list, :create, :details, :update, :delete],
        do: false

    def authorized?(_division, action, user, _meta)
        when action in [:details, :list, :versioning, :deleted_versioning],
        do:
          Enum.any?(
            [:viewer, :tracer, :super_user, :supervisor, :admin],
            &User.has_role?(user, &1, :any)
          )

    def authorized?(_division, action, user, _meta)
        when action in [:create, :update],
        do:
          Enum.any?([:tracer, :super_user, :supervisor, :admin], &User.has_role?(user, &1, :any))

    def authorized?(division, action, user, _meta)
        when action in [:delete] do
      cond do
        Enum.any?([:super_user, :supervisor, :admin], &User.has_role?(user, &1, :any)) ->
          true

        Enum.any?([:tracer], &User.has_role?(user, &1, :any)) ->
          not OrganisationContext.has_affiliations?(division)
      end
    end
  end
end
