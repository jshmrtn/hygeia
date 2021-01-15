defmodule Hygeia.CaseContext.Note do
  @moduledoc """
  Model for Note
  """

  use Hygeia, :model

  alias Hygeia.CaseContext.Case
  alias Hygeia.TenantContext.Tenant

  @type empty :: %__MODULE__{
          note: String.t() | nil,
          case_uuid: String.t() | nil,
          case: Ecto.Schema.belongs_to(Case.t()) | nil,
          tenant: Ecto.Schema.has_one(Tenant.t()) | nil,
          inserted_at: DateTime.t() | nil,
          updated_at: DateTime.t() | nil
        }

  @type t :: %__MODULE__{
          note: String.t(),
          case_uuid: String.t(),
          case: Ecto.Schema.belongs_to(Case.t()),
          tenant: Ecto.Schema.has_one(Tenant.t()),
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  schema "notes" do
    field :note, :string

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
      |> cast(attrs, [:uuid, :note])
      |> fill_uuid()
      |> validate_required([:note])
      |> assoc_constraint(:case)

  defimpl Hygeia.Authorization.Resource do
    alias Hygeia.CaseContext.Note
    alias Hygeia.UserContext.User

    @spec authorized?(
            resource :: Note.t(),
            action :: :create,
            user :: :anonymous | User.t(),
            meta :: %{atom() => term}
          ) :: boolean
    def authorized?(_note, action, :anonymous, _meta)
        when action in [:create],
        do: false

    def authorized?(_note, :create, user, %{case: %Case{tenant_uuid: tenant_uuid}}),
      do:
        Enum.any?(
          [:tracer, :supervisor, :super_user, :admin],
          &User.has_role?(user, &1, tenant_uuid)
        )
  end
end
