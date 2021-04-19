defmodule Hygeia.CaseContext.Case do
  @moduledoc """
  Case Model
  """
  use Hygeia, :model

  import EctoEnum
  import HygeiaGettext

  alias Hygeia.CaseContext.Case.Clinical
  alias Hygeia.CaseContext.Case.Hospitalization
  alias Hygeia.CaseContext.Case.Monitoring
  alias Hygeia.CaseContext.Case.Phase
  alias Hygeia.CaseContext.ExternalReference
  alias Hygeia.CaseContext.Note
  alias Hygeia.CaseContext.Person
  alias Hygeia.CaseContext.PossibleIndexSubmission
  alias Hygeia.CaseContext.Transmission
  alias Hygeia.CommunicationContext.Email
  alias Hygeia.CommunicationContext.SMS
  alias Hygeia.Repo
  alias Hygeia.TenantContext.Tenant
  alias Hygeia.UserContext.User

  defenum Complexity, :case_complexity, ["low", "medium", "high", "extreme"]

  defenum Status, :case_status, [
    "first_contact",
    "first_contact_unreachable",
    "code_pending",
    "waiting_for_contact_person_list",
    "other_actions_todo",
    "next_contact_agreed",
    "hospitalization",
    "home_resident",
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
          possible_index_submissions: Ecto.Schema.many_to_many(PossibleIndexSubmission.t()) | nil,
          emails: Ecto.Schema.has_many(Email.t()) | nil,
          sms: Ecto.Schema.has_many(SMS.t()) | nil,
          notes: Ecto.Schema.has_many(Note.t()) | nil,
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
          tracer_uuid: String.t() | nil,
          tracer: Ecto.Schema.belongs_to(User.t()) | nil,
          supervisor_uuid: String.t() | nil,
          supervisor: Ecto.Schema.belongs_to(User.t()) | nil,
          possible_index_submissions: Ecto.Schema.many_to_many(PossibleIndexSubmission.t()),
          emails: Ecto.Schema.has_many(Email.t()),
          sms: Ecto.Schema.has_many(SMS.t()),
          notes: Ecto.Schema.has_many(Note.t()),
          inserted_at: NaiveDateTime.t(),
          updated_at: NaiveDateTime.t()
        }

  @derive {Phoenix.Param, key: :uuid}

  schema "cases" do
    field :complexity, Complexity
    field :human_readable_id, :string
    field :status, Status, default: :first_contact

    embeds_one :clinical, Clinical, on_replace: :update
    embeds_many :external_references, ExternalReference, on_replace: :delete
    embeds_many :hospitalizations, Hospitalization, on_replace: :delete
    embeds_one :monitoring, Monitoring, on_replace: :update
    embeds_many :phases, Phase, on_replace: :delete

    belongs_to :person, Person, references: :uuid, foreign_key: :person_uuid
    belongs_to :tenant, Tenant, references: :uuid, foreign_key: :tenant_uuid
    belongs_to :tracer, User, references: :uuid, foreign_key: :tracer_uuid
    belongs_to :supervisor, User, references: :uuid, foreign_key: :supervisor_uuid
    # , references: :recipient_case
    has_many :received_transmissions, Transmission, foreign_key: :recipient_case_uuid
    # , references: :propagator_case
    has_many :propagated_transmissions, Transmission, foreign_key: :propagator_case_uuid
    has_many :possible_index_submissions, PossibleIndexSubmission, foreign_key: :case_uuid
    has_many :emails, Email, foreign_key: :case_uuid
    has_many :sms, SMS, foreign_key: :case_uuid
    has_many :notes, Note, foreign_key: :case_uuid

    timestamps()
  end

  @doc false
  @spec changeset(
          case :: empty | t | Ecto.Changeset.t(t | empty),
          attrs :: Hygeia.ecto_changeset_params()
        ) ::
          Ecto.Changeset.t(t)
  def changeset(case, attrs) do
    case
    |> cast(attrs, [
      :uuid,
      :human_readable_id,
      :complexity,
      :status,
      :tracer_uuid,
      :supervisor_uuid,
      :tenant_uuid,
      :person_uuid,
      :inserted_at
    ])
    |> fill_uuid
    |> fill_human_readable_id
    |> prefill_first_phase
    |> validate_required([
      :uuid,
      :human_readable_id,
      :status,
      :tenant_uuid,
      :person_uuid
    ])
    |> cast_embed(:clinical)
    |> cast_embed(:external_references)
    |> cast_embed(:hospitalizations)
    |> cast_embed(:monitoring)
    |> cast_embed(:phases, required: true)
    |> validate_at_least_one_phase()
    |> validate_phase_type_unique()
  end

  defp prefill_first_phase(changeset) do
    changeset
    |> fetch_field!(:phases)
    |> case do
      [] -> put_embed(changeset, :phases, [%Phase{}])
      _other -> changeset
    end
  end

  defp validate_at_least_one_phase(changeset) do
    validate_change(changeset, :phases, fn :phases, phases ->
      phases
      |> Enum.reject(&match?(%Changeset{action: action} when action in [:replace, :delete], &1))
      |> case do
        [] -> [phases: gettext("At least one phase is required")]
        [_ | _] -> []
      end
    end)
  end

  defp validate_phase_type_unique(changeset) do
    validate_change(changeset, :phases, fn :phases, phases ->
      keep_phases =
        Enum.reject(
          phases,
          &match?(%Changeset{action: action} when action in [:replace, :delete], &1)
        )

      unique_phases =
        Enum.uniq_by(keep_phases, fn phase_changeset ->
          case fetch_field!(phase_changeset, :details) do
            nil -> make_ref()
            %Phase.Index{} -> :index
            %Phase.PossibleIndex{type: type} -> {:possible_index, type}
          end
        end)

      if length(unique_phases) == length(keep_phases) do
        []
      else
        [phases: gettext("Case Phase Type must be unique")]
      end
    end)
  end

  defimpl Hygeia.Authorization.Resource do
    alias Hygeia.CaseContext.Case
    alias Hygeia.Repo
    alias Hygeia.TenantContext.Tenant
    alias Hygeia.UserContext.User

    @spec preload(resource :: Case.t()) :: Case.t()
    def preload(resource), do: Repo.preload(resource, :tenant)

    @spec authorized?(
            resource :: Case.t(),
            action :: :details | :partial_details | :create | :list | :update | :delete,
            user :: :anonymous | User.t() | Person.t(),
            meta :: %{atom() => term}
          ) :: boolean
    def authorized?(_case, action, :anonymous, _meta)
        when action in [:list, :create, :details, :partial_details, :update, :delete],
        do: false

    def authorized?(
          %Case{person_uuid: person_uuid},
          :partial_details,
          %Person{uuid: person_uuid},
          _meta
        ),
        do: true

    def authorized?(_case, action, %Person{}, _meta)
        when action in [:list, :create, :details, :partial_details, :update, :delete],
        do: false

    def authorized?(
          %Case{tracer_uuid: tracer_uuid},
          action,
          %User{uuid: tracer_uuid} = user,
          _meta
        )
        when action in [:details, :partial_details],
        do: User.has_role?(user, :tracer, :any)

    def authorized?(
          %Case{supervisor_uuid: supervisor_uuid},
          action,
          %User{uuid: supervisor_uuid} = user,
          _meta
        )
        when action in [:details, :partial_details],
        do: User.has_role?(user, :supervisor, :any)

    def authorized?(%Case{tenant: %Tenant{iam_domain: nil}}, action, user, _meta)
        when action in [:details, :partial_details, :versioning, :update, :delete],
        do:
          Enum.any?(
            [:super_user, :supervisor, :admin],
            &User.has_role?(user, &1, :any)
          )

    def authorized?(%Case{tenant_uuid: tenant_uuid}, action, user, _meta)
        when action in [:details, :partial_details, :versioning],
        do:
          Enum.any?(
            [:viewer, :tracer, :super_user, :supervisor, :admin],
            &User.has_role?(user, &1, tenant_uuid)
          )

    def authorized?(_module, :deleted_versioning, user, _meta),
      do: User.has_role?(user, :admin, :any)

    def authorized?(%Case{tenant_uuid: old_tenant_uuid}, :update, user, %{tenant: tenant}),
      do:
        Enum.any?(
          [:tracer, :super_user, :supervisor, :admin],
          &User.has_role?(user, &1, old_tenant_uuid)
        ) and
          Enum.any?(
            [:tracer, :super_user, :supervisor, :admin],
            &User.has_role?(user, &1, tenant)
          )

    def authorized?(%Case{tenant_uuid: tenant_uuid}, :update, user, _meta),
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

    def authorized?(_module, :create, user, %{tenant: %Tenant{case_management_enabled: true}}),
      do: Enum.any?([:tracer, :super_user, :supervisor, :admin], &User.has_role?(user, &1, :any))

    def authorized?(_module, :create, _user, %{tenant: %Tenant{case_management_enabled: false}}),
      do: false

    def authorized?(_module, :create, user, %{tenant: :any}),
      do: Enum.any?([:tracer, :super_user, :supervisor, :admin], &User.has_role?(user, &1, :any))

    def authorized?(%Case{tenant_uuid: tenant_uuid}, action, user, _meta)
        when action in [:delete],
        do: Enum.any?([:super_user, :supervisor, :admin], &User.has_role?(user, &1, tenant_uuid))
  end
end
