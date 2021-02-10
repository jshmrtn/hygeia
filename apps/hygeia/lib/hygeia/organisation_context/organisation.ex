defmodule Hygeia.OrganisationContext.Organisation do
  @moduledoc """
  Model for Organisations
  """

  use Hygeia, :model

  alias Hygeia.CaseContext.Address
  alias Hygeia.CaseContext.Case
  alias Hygeia.OrganisationContext
  alias Hygeia.OrganisationContext.Affiliation
  alias Hygeia.OrganisationContext.Position

  @derive {Phoenix.Param, key: :uuid}

  @type empty :: %__MODULE__{
          uuid: String.t() | nil,
          name: String.t() | nil,
          address: Address.t() | nil,
          notes: String.t() | nil,
          positions: Ecto.Schema.has_many(Position.t()) | nil,
          related_cases: Ecto.Schema.many_to_many(Case.t()) | nil,
          affiliations: Ecto.Schema.has_many(Affiliation.t()) | nil,
          inserted_at: NaiveDateTime.t() | nil,
          updated_at: NaiveDateTime.t() | nil
        }
  @type t :: %__MODULE__{
          uuid: String.t(),
          name: String.t(),
          address: Address.t(),
          notes: String.t() | nil,
          positions: Ecto.Schema.has_many(Position.t()),
          related_cases: Ecto.Schema.many_to_many(Case.t()),
          affiliations: Ecto.Schema.has_many(Affiliation.t()),
          inserted_at: NaiveDateTime.t(),
          updated_at: NaiveDateTime.t()
        }

  schema "organisations" do
    field :name, :string
    field :notes, :string

    embeds_one :address, Address, on_replace: :delete
    has_many :positions, Position, foreign_key: :organisation_uuid, on_replace: :delete
    has_many :affiliations, Affiliation, foreign_key: :organisation_uuid, on_replace: :delete

    many_to_many :related_cases, Case,
      join_through: "case_related_organisations",
      join_keys: [organisation_uuid: :uuid, case_uuid: :uuid],
      on_replace: :delete

    field :suspected_duplicates_uuid, {:array, :binary_id}, virtual: true, default: []

    timestamps()
  end

  @doc false
  @spec changeset(organisation :: t | empty, attrs :: Hygeia.ecto_changeset_params()) ::
          Changeset.t()
  def changeset(organisation, attrs) do
    organisation
    |> cast(attrs, [:name, :notes])
    |> validate_required([:name])
    |> cast_embed(:address)
    |> cast_assoc(:positions)
    |> check_duplicates()
  end

  defp check_duplicates(%Ecto.Changeset{valid?: true} = changeset),
    do:
      put_change(
        changeset,
        :suspected_duplicates_uuid,
        changeset
        |> apply_changes()
        |> OrganisationContext.list_possible_organisation_duplicates()
        |> Enum.map(& &1.uuid)
      )

  defp check_duplicates(changeset), do: changeset

  defimpl Hygeia.Authorization.Resource do
    alias Hygeia.OrganisationContext.Organisation
    alias Hygeia.UserContext.User

    @spec preload(resource :: Organisation.t()) :: Organisation.t()
    def preload(resource), do: resource

    @spec authorized?(
            resource :: Organisation.t(),
            action :: :create | :list | :details | :update | :delete,
            user :: :anonymous | User.t(),
            meta :: %{atom() => term}
          ) :: boolean
    def authorized?(_organisation, action, :anonymous, _meta)
        when action in [:list, :create, :details, :update, :delete],
        do: false

    def authorized?(_organisation, action, user, _meta)
        when action in [:details, :list, :versioning, :deleted_versioning],
        do:
          Enum.any?(
            [:viewer, :tracer, :super_user, :supervisor, :admin],
            &User.has_role?(user, &1, :any)
          )

    def authorized?(_organisation, action, user, _meta)
        when action in [:create, :update, :delete],
        do:
          Enum.any?([:tracer, :super_user, :supervisor, :admin], &User.has_role?(user, &1, :any))
  end
end
