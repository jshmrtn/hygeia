defmodule Hygeia.CaseContext.Note do
  @moduledoc """
  Model for Note
  """

  use Hygeia, :model

  alias Hygeia.CaseContext.Case
  alias Hygeia.TenantContext.Tenant

  @type empty :: %__MODULE__{
          note: String.t() | nil,
          case_uuid: Ecto.UUID.t() | nil,
          case: Ecto.Schema.belongs_to(Case.t()) | nil,
          tenant: Ecto.Schema.has_one(Tenant.t()) | nil,
          pinned: boolean | nil,
          inserted_at: DateTime.t() | nil,
          updated_at: DateTime.t() | nil
        }

  @type t :: %__MODULE__{
          note: String.t(),
          case_uuid: Ecto.UUID.t(),
          case: Ecto.Schema.belongs_to(Case.t()),
          tenant: Ecto.Schema.has_one(Tenant.t()),
          pinned: boolean,
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  schema "notes" do
    field :note, :string
    field :pinned, :boolean, default: false

    belongs_to :case, Case, references: :uuid, foreign_key: :case_uuid
    has_one :tenant, through: [:case, :tenant]

    timestamps()
  end

  @spec changeset(
          note :: resource | Changeset.t(resource),
          attrs :: Hygeia.ecto_changeset_params()
        ) :: Ecto.Changeset.t(resource)
        when resource: t() | empty()
  def changeset(note, attrs),
    do:
      note
      |> cast(attrs, [:uuid, :note, :pinned])
      |> fill_uuid()
      |> validate_required([:note])
      |> assoc_constraint(:case)

  defimpl Hygeia.Authorization.Resource do
    alias Hygeia.CaseContext.Note
    alias Hygeia.CaseContext.Person
    alias Hygeia.UserContext.User

    @spec preload(resource :: Note.t()) :: Note.t()
    def preload(resource), do: resource

    @spec authorized?(
            resource :: Note.t(),
            action :: :create | :list,
            user :: :anonymous | User.t() | Person.t(),
            meta :: %{atom() => term}
          ) :: boolean
    def authorized?(_note, action, :anonymous, _meta)
        when action in [:create],
        do: false

    def authorized?(_note, action, %Person{}, _meta)
        when action in [:create],
        do: false

    def authorized?(_note, :create, _user, %{case: %Case{anonymized: true}}), do: false

    def authorized?(_note, :create, user, %{case: %Case{tenant_uuid: tenant_uuid}}),
      do:
        Enum.any?(
          [:tracer, :supervisor, :super_user, :admin],
          &User.has_role?(user, &1, tenant_uuid)
        )

    def authorized?(_note, :list, user, %{person: %Person{tenant_uuid: tenant_uuid}}),
      do:
        Enum.any?(
          [:tracer, :supervisor, :super_user, :admin],
          &User.has_role?(user, &1, tenant_uuid)
        )
  end
end
