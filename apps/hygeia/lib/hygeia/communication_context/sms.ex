defmodule Hygeia.CommunicationContext.SMS do
  @moduledoc """
  Model for SMS
  """

  use Hygeia, :model

  import EctoEnum

  alias Hygeia.CaseContext.Case
  alias Hygeia.CommunicationContext.Direction
  alias Hygeia.TenantContext.Tenant

  defenum Status, :sms_status, [
    :in_progress,
    :success,
    :failure
  ]

  @type empty :: %__MODULE__{
          direction: Direction.t() | nil,
          status: Status.t() | nil,
          message: String.t() | nil,
          number: String.t() | nil,
          delivery_receipt_id: String.t() | nil,
          case_uuid: String.t() | nil,
          case: Ecto.Schema.belongs_to(Case.t()) | nil,
          tenant: Ecto.Schema.has_one(Tenant.t()) | nil,
          inserted_at: DateTime.t() | nil,
          updated_at: DateTime.t() | nil
        }

  @type t :: %__MODULE__{
          direction: Direction.t(),
          status: Status.t(),
          message: String.t(),
          number: String.t(),
          delivery_receipt_id: String.t() | nil,
          case_uuid: String.t(),
          case: Ecto.Schema.belongs_to(Case.t()),
          tenant: Ecto.Schema.has_one(Tenant.t()),
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  schema "sms" do
    field :direction, Direction
    field :status, Status
    field :message, :string
    field :number, :string
    field :delivery_receipt_id, :string

    belongs_to :case, Case, references: :uuid, foreign_key: :case_uuid
    has_one :tenant, through: [:case, :tenant]

    timestamps()
  end

  @spec changeset(
          sms :: resource | Changeset.t(resource),
          attrs :: Hygeia.ecto_changeset_params()
        ) :: Ecto.Changeset.t(resource)
        when resource: t() | empty()
  def changeset(sms, attrs),
    do:
      sms
      |> cast(attrs, [
        :uuid,
        :direction,
        :status,
        :message,
        :number,
        :delivery_receipt_id,
        :inserted_at
      ])
      |> fill_uuid()
      |> validate_required([:uuid, :direction, :status, :message, :number])
      |> validate_and_normalize_phone(:number)
      |> assoc_constraint(:case)

  defimpl Hygeia.Authorization.Resource do
    alias Hygeia.CaseContext.Person
    alias Hygeia.CommunicationContext.SMS
    alias Hygeia.UserContext.User

    @spec preload(resource :: SMS.t()) :: SMS.t()
    def preload(resource), do: resource

    @spec authorized?(
            resource :: SMS.t(),
            action :: :create,
            user :: :anonymous | User.t() | Person.t(),
            meta :: %{atom() => term}
          ) :: boolean
    def authorized?(_sms, action, :anonymous, _meta)
        when action in [:create],
        do: false

    def authorized?(_sms, action, %Person{}, _meta)
        when action in [:create],
        do: false

    def authorized?(_sms, :create, user, %{case: %Case{tenant_uuid: tenant_uuid}}),
      do:
        Enum.any?(
          [:tracer, :supervisor, :super_user, :admin],
          &User.has_role?(user, &1, tenant_uuid)
        )
  end
end
