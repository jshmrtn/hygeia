defmodule Hygeia.CaseContext.Case do
  @moduledoc """
  Case Model
  """
  use Hygeia, :model

  import EctoEnum

  alias Hygeia.CaseContext.Clinical
  alias Hygeia.CaseContext.ExternalReference
  alias Hygeia.CaseContext.Hospitalization
  alias Hygeia.CaseContext.Monitoring
  alias Hygeia.CaseContext.Person
  alias Hygeia.CaseContext.Phase
  alias Hygeia.CaseContext.ProtocolEntry
  alias Hygeia.CaseContext.Transmission
  alias Hygeia.TenantContext.Tenant
  alias Hygeia.UserContext.User

  defenum Complexity, :complexity, ["low", "medium", "high", "extreme"]

  defenum Status, :complexity, [
    "new",
    "first_contact",
    "first_check",
    "tracing",
    "care",
    "second_check",
    "done"
  ]

  @type empty :: %__MODULE__{
          uuid: String.t() | nil,
          human_readable_id: String.t() | nil,
          complexity: Complexity.t() | nil,
          status: Status.t() | nil,
          clinical: Clinical.t() | nil,
          external_references: [ExternalReference.t()] | nil,
          hospitalizations: [Hospitalization.t()] | nil,
          monitoring: Monitoring.t() | nil,
          phases: [Phase.t()] | nil,
          person_uuid: String.t() | nil,
          person: Ecto.Schema.belongs_to(Person.t()) | nil,
          tenant_uuid: String.t() | nil,
          tenant: Ecto.Schema.belongs_to(Tenant.t()) | nil,
          tracer_uuid: String.t() | nil,
          tracer: Ecto.Schema.belongs_to(User.t()) | nil,
          supervisor_uuid: String.t() | nil,
          supervisor: Ecto.Schema.belongs_to(User.t()) | nil,
          protocol_entries: Ecto.Schema.has_many(ProtocolEntry.t()) | nil,
          inserted_at: NaiveDateTime.t() | nil,
          updated_at: NaiveDateTime.t() | nil
        }

  @type t :: %__MODULE__{
          uuid: String.t(),
          human_readable_id: String.t(),
          complexity: Complexity.t() | nil,
          status: Status.t(),
          clinical: Clinical.t(),
          external_references: [ExternalReference.t()],
          hospitalizations: [Hospitalization.t()],
          monitoring: Monitoring.t(),
          phases: [Phase.t()],
          person_uuid: String.t(),
          person: Ecto.Schema.belongs_to(Person.t()),
          tenant_uuid: String.t(),
          tenant: Ecto.Schema.belongs_to(Tenant.t()),
          tracer_uuid: String.t(),
          tracer: Ecto.Schema.belongs_to(User.t()),
          supervisor_uuid: String.t(),
          supervisor: Ecto.Schema.belongs_to(User.t()),
          protocol_entries: Ecto.Schema.has_many(ProtocolEntry.t()),
          inserted_at: NaiveDateTime.t(),
          updated_at: NaiveDateTime.t()
        }

  @derive {Phoenix.Param, key: :uuid}

  schema "cases" do
    field :complexity, Complexity
    field :human_readable_id, :string
    field :status, Status, default: :in_progress

    embeds_one :clinical, Clinical
    embeds_many :external_references, ExternalReference
    embeds_many :hospitalizations, Hospitalization
    embeds_one :monitoring, Monitoring
    embeds_many :phases, Phase

    belongs_to :person, Person, references: :uuid, foreign_key: :person_uuid
    belongs_to :tenant, Tenant, references: :uuid, foreign_key: :tenant_uuid
    belongs_to :tracer, User, references: :uuid, foreign_key: :tracer_uuid
    belongs_to :supervisor, User, references: :uuid, foreign_key: :supervisor_uuid
    # , references: :recipient_case
    has_many :received_transmissions, Transmission, foreign_key: :recipient_case_uuid
    # , references: :propagator_case
    has_many :propagated_transmissions, Transmission, foreign_key: :propagator_case_uuid
    has_many :protocol_entries, ProtocolEntry, foreign_key: :case_uuid

    timestamps()
  end

  @doc false
  @spec changeset(case :: empty | t, attrs :: Hygeia.ecto_changeset_params()) ::
          Ecto.Changeset.t()
  def changeset(case, attrs) do
    case
    |> cast(attrs, [
      :human_readable_id,
      :complexity,
      :status,
      :tracer_uuid,
      :supervisor_uuid,
      :tenant_uuid,
      :person_uuid
    ])
    |> fill_uuid
    |> fill_human_readable_id
    |> prefill_first_phase
    |> validate_required([
      :uuid,
      :human_readable_id,
      :status,
      :tracer_uuid,
      :supervisor_uuid,
      :tenant_uuid,
      :person_uuid
    ])
    |> cast_embed(:clinical)
    |> cast_embed(:external_references)
    |> cast_embed(:hospitalizations)
    |> cast_embed(:monitoring)
    |> cast_embed(:phases, required: true)
  end

  defp prefill_first_phase(changeset) do
    changeset
    |> fetch_field!(:phases)
    |> case do
      [] -> put_embed(changeset, :phases, [%Phase{}])
      _other -> changeset
    end
  end
end
