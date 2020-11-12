defmodule Hygeia.OrganisationContext.Organisation do
  @moduledoc """
  Model for Organisations
  """

  use Hygeia, :model

  alias Hygeia.CaseContext.Address
  alias Hygeia.CaseContext.Case
  alias Hygeia.OrganisationContext.Position

  @derive {Phoenix.Param, key: :uuid}

  @type empty :: %__MODULE__{
          uuid: String.t() | nil,
          name: String.t() | nil,
          address: Address.t() | nil,
          notes: String.t() | nil,
          positions: Ecto.Schema.has_many(Position.t()) | nil,
          related_cases: Ecto.Schema.many_to_many(Case.t()) | nil,
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
          inserted_at: NaiveDateTime.t(),
          updated_at: NaiveDateTime.t()
        }

  schema "organisations" do
    field :name, :string
    field :notes, :string

    embeds_one :address, Address, on_replace: :delete
    has_many :positions, Position, foreign_key: :organisation_uuid, on_replace: :delete

    many_to_many :related_cases, Case,
      join_through: "case_related_organisations",
      join_keys: [organisation_uuid: :uuid, case_uuid: :uuid]

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
  end

  defimpl Hygeia.Authorization.Resource do
    alias Hygeia.OrganisationContext.Organisation
    alias Hygeia.UserContext.User

    @spec authorized?(
            resource :: Organisation.t(),
            action :: :create | :list | :details | :update | :delete,
            user :: :anonymous | User.t(),
            meta :: %{atom() => term}
          ) :: boolean
    def authorized?(_organisation, action, :anonymous, _meta)
        when action in [:list, :create, :details, :update, :delete],
        do: false

    def authorized?(_organisation, action, %User{}, _meta)
        when action in [:details, :list],
        do: true

    def authorized?(_organisation, action, %User{roles: roles}, _meta)
        when action in [:create, :update, :delete],
        do: :tracer in roles or :supervisor in roles or :admin in roles
  end
end
