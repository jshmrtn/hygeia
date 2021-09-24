defmodule Hygeia.OrganisationContext.Organisation do
  @moduledoc """
  Model for Organisations
  """

  use Hygeia, :model

  alias Hygeia.CaseContext.Address
  alias Hygeia.CaseContext.Hospitalization
  alias Hygeia.OrganisationContext
  alias Hygeia.OrganisationContext.Affiliation
  alias Hygeia.OrganisationContext.Division
  alias Hygeia.OrganisationContext.Organisation.SchoolType
  alias Hygeia.OrganisationContext.Organisation.Type
  alias Hygeia.OrganisationContext.Position

  @derive {Phoenix.Param, key: :uuid}

  @type empty :: %__MODULE__{
          uuid: Ecto.UUID.t() | nil,
          name: String.t() | nil,
          type: Type.t() | nil,
          type_other: String.t() | nil,
          school_type: SchoolType.t() | nil,
          address: Address.t() | nil,
          notes: String.t() | nil,
          positions: Ecto.Schema.has_many(Position.t()) | nil,
          affiliations: Ecto.Schema.has_many(Affiliation.t()) | nil,
          divisions: Ecto.Schema.has_many(Division.t()) | nil,
          hospitalizations: Ecto.Schema.has_many(Hospitalization.t()) | nil,
          inserted_at: DateTime.t() | nil,
          updated_at: DateTime.t() | nil
        }
  @type t :: %__MODULE__{
          uuid: Ecto.UUID.t(),
          name: String.t(),
          type: Type.t() | nil,
          type_other: String.t() | nil,
          school_type: SchoolType.t() | nil,
          address: Address.t(),
          notes: String.t() | nil,
          positions: Ecto.Schema.has_many(Position.t()),
          affiliations: Ecto.Schema.has_many(Affiliation.t()),
          divisions: Ecto.Schema.has_many(Division.t()),
          hospitalizations: Ecto.Schema.has_many(Hospitalization.t()),
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  schema "organisations" do
    field :name, :string
    field :notes, :string
    field :type, Type
    field :type_other, :string
    field :school_type, SchoolType

    embeds_one :address, Address, on_replace: :delete
    has_many :positions, Position, foreign_key: :organisation_uuid, on_replace: :delete
    has_many :affiliations, Affiliation, foreign_key: :organisation_uuid, on_replace: :delete
    has_many :divisions, Division, foreign_key: :organisation_uuid, on_replace: :delete

    has_many :hospitalizations, Hospitalization,
      foreign_key: :organisation_uuid,
      on_replace: :delete

    field :suspected_duplicates_uuid, {:array, :binary_id}, virtual: true, default: []

    timestamps()
  end

  @doc false
  @spec changeset(organisation :: t | empty, attrs :: Hygeia.ecto_changeset_params()) ::
          Changeset.t()
  def changeset(organisation, attrs) do
    organisation
    |> cast(attrs, [:name, :notes, :type, :type_other, :school_type])
    |> validate_required([:name])
    |> cast_embed(:address)
    |> cast_assoc(:positions)
    |> check_duplicates()
    |> validate_type_other()
    |> validate_school_type()
  end

  defp validate_school_type(changeset) do
    changeset
    |> fetch_field!(:type)
    |> case do
      :school -> validate_required(changeset, [:school_type])
      _defined -> put_change(changeset, :school_type, nil)
    end
  end

  defp validate_type_other(changeset) do
    changeset
    |> fetch_field!(:type)
    |> case do
      :other -> validate_required(changeset, [:type_other])
      _defined -> put_change(changeset, :type_other, nil)
    end
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
    alias Hygeia.CaseContext.Person
    alias Hygeia.OrganisationContext
    alias Hygeia.OrganisationContext.Organisation
    alias Hygeia.UserContext.User

    @spec preload(resource :: Organisation.t()) :: Organisation.t()
    def preload(resource), do: resource

    @spec authorized?(
            resource :: Organisation.t(),
            action :: :create | :list | :details | :update | :delete,
            user :: :anonymous | User.t() | Person.t(),
            meta :: %{atom() => term}
          ) :: boolean
    def authorized?(_organisation, action, :anonymous, _meta)
        when action in [:list, :create, :details, :update, :delete],
        do: false

    def authorized?(_organisation, action, %Person{}, _meta)
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
        when action in [:create, :update],
        do:
          Enum.any?([:tracer, :super_user, :supervisor, :admin], &User.has_role?(user, &1, :any))

    def authorized?(organisation, action, user, _meta)
        when action in [:delete] do
      cond do
        Enum.any?([:super_user, :supervisor, :admin], &User.has_role?(user, &1, :any)) ->
          true

        Enum.any?([:tracer], &User.has_role?(user, &1, :any)) ->
          not OrganisationContext.has_affiliations?(organisation)

        true ->
          false
      end
    end
  end
end
