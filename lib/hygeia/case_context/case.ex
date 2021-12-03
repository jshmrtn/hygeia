defmodule Hygeia.CaseContext.Case do
  @moduledoc """
  Case Model
  """
  use Hygeia, :model

  import HygeiaGettext

  alias Hygeia.AutoTracingContext.AutoTracing
  alias Hygeia.CaseContext.Case.Clinical
  alias Hygeia.CaseContext.Case.Complexity
  alias Hygeia.CaseContext.Case.Monitoring
  alias Hygeia.CaseContext.Case.Phase
  alias Hygeia.CaseContext.Case.Status
  alias Hygeia.CaseContext.ExternalReference
  alias Hygeia.CaseContext.Hospitalization
  alias Hygeia.CaseContext.Note
  alias Hygeia.CaseContext.Person
  alias Hygeia.CaseContext.PossibleIndexSubmission
  alias Hygeia.CaseContext.PrematureRelease
  alias Hygeia.CaseContext.Test
  alias Hygeia.CaseContext.Transmission
  alias Hygeia.CommunicationContext.Email
  alias Hygeia.CommunicationContext.SMS
  alias Hygeia.OrganisationContext.Visit
  alias Hygeia.Repo
  alias Hygeia.TenantContext.Tenant
  alias Hygeia.UserContext.User

  @max_days_for_phase_start_in_the_past 5

  @phase_type_order [:outbreak, :covid_app, :travel, :contact_person, :other, :index]
                    |> Enum.with_index()
                    |> Map.new()

  @type empty :: %__MODULE__{
          uuid: Ecto.UUID.t() | nil,
          human_readable_id: String.t() | nil,
          complexity: Complexity.t() | nil,
          status: Status.t() | nil,
          clinical: Clinical.t() | nil,
          external_references: [ExternalReference.t()] | nil,
          hospitalizations: Ecto.Schema.has_many(Hospitalization.t()) | nil,
          monitoring: Monitoring.t() | nil,
          phases: [Phase.t()] | nil,
          person_uuid: Ecto.UUID.t() | nil,
          person: Ecto.Schema.belongs_to(Person.t()) | nil,
          tenant_uuid: Ecto.UUID.t() | nil,
          tenant: Ecto.Schema.belongs_to(Tenant.t()) | nil,
          tracer_uuid: Ecto.UUID.t() | nil,
          tracer: Ecto.Schema.belongs_to(User.t()) | nil,
          supervisor_uuid: Ecto.UUID.t() | nil,
          supervisor: Ecto.Schema.belongs_to(User.t()) | nil,
          possible_index_submissions: Ecto.Schema.many_to_many(PossibleIndexSubmission.t()) | nil,
          emails: Ecto.Schema.has_many(Email.t()) | nil,
          sms: Ecto.Schema.has_many(SMS.t()) | nil,
          notes: Ecto.Schema.has_many(Note.t()) | nil,
          pinned_notes: Ecto.Schema.has_many(Note.t()) | nil,
          visits: Ecto.Schema.has_many(Visit.t()),
          tests: Ecto.Schema.has_many(Test.t()) | nil,
          premature_releases: Ecto.Schema.has_many(PrematureRelease.t()) | nil,
          auto_tracing: Ecto.Schema.has_one(AutoTracing.t()) | nil,
          inserted_at: DateTime.t() | nil,
          updated_at: DateTime.t() | nil
        }

  @type t :: %__MODULE__{
          uuid: Ecto.UUID.t(),
          human_readable_id: String.t(),
          complexity: Complexity.t() | nil,
          status: Status.t(),
          clinical: Clinical.t(),
          external_references: [ExternalReference.t()],
          hospitalizations: Ecto.Schema.has_many(Hospitalization.t()),
          monitoring: Monitoring.t() | nil,
          phases: [Phase.t()],
          person_uuid: Ecto.UUID.t(),
          person: Ecto.Schema.belongs_to(Person.t()),
          tenant_uuid: Ecto.UUID.t(),
          tenant: Ecto.Schema.belongs_to(Tenant.t()),
          tracer_uuid: Ecto.UUID.t() | nil,
          tracer: Ecto.Schema.belongs_to(User.t()) | nil,
          supervisor_uuid: Ecto.UUID.t() | nil,
          supervisor: Ecto.Schema.belongs_to(User.t()) | nil,
          possible_index_submissions: Ecto.Schema.many_to_many(PossibleIndexSubmission.t()),
          emails: Ecto.Schema.has_many(Email.t()),
          sms: Ecto.Schema.has_many(SMS.t()),
          notes: Ecto.Schema.has_many(Note.t()),
          pinned_notes: Ecto.Schema.has_many(Note.t()),
          visits: Ecto.Schema.has_many(Visit.t()),
          tests: Ecto.Schema.has_many(Test.t()),
          premature_releases: Ecto.Schema.has_many(PrematureRelease.t()),
          auto_tracing: Ecto.Schema.has_one(AutoTracing.t()) | nil,
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  @type changeset_params :: %{optional(:symptoms_required) => boolean()}

  @derive {Phoenix.Param, key: :uuid}

  schema "cases" do
    field :complexity, Complexity
    field :human_readable_id, :string
    field :status, Status, default: :first_contact

    embeds_one :clinical, Clinical, on_replace: :update
    embeds_many :external_references, ExternalReference, on_replace: :delete
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
    has_many :pinned_notes, Note, foreign_key: :case_uuid, where: [pinned: true]
    has_many :hospitalizations, Hospitalization, foreign_key: :case_uuid, on_replace: :delete
    has_many :visits, Visit, foreign_key: :case_uuid, on_replace: :delete
    has_many :tests, Test, foreign_key: :case_uuid, on_replace: :delete
    has_many :premature_releases, PrematureRelease, foreign_key: :case_uuid, on_replace: :delete

    has_one :auto_tracing, AutoTracing, foreign_key: :case_uuid

    timestamps()
  end

  @doc false
  @spec changeset(
          case :: empty | t | Ecto.Changeset.t(t | empty),
          attrs :: Hygeia.ecto_changeset_params(),
          changeset_params :: changeset_params
        ) ::
          Ecto.Changeset.t(t)
  def changeset(case, attrs \\ %{}, changeset_params \\ %{})

  def changeset(case, attrs, %{symptoms_required: true} = changeset_params) do
    case
    |> changeset(attrs, %{changeset_params | symptoms_required: false})
    |> cast_embed(:clinical,
      with: &Clinical.changeset(&1, &2, %{symptoms_required: true}),
      required: true
    )
    |> validate_clinical_required()
  end

  def changeset(case, attrs, _changeset_params) do
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
    |> validate_required([
      :uuid,
      :human_readable_id,
      :status,
      :tenant_uuid,
      :person_uuid
    ])
    |> cast_embed(:clinical)
    |> cast_embed(:external_references)
    |> cast_assoc(:hospitalizations)
    |> cast_assoc(:visits)
    |> cast_assoc(:tests)
    |> cast_embed(:monitoring)
    |> cast_embed(:phases, required: true)
    |> validate_at_least_one_phase()
    |> validate_phase_type_unique()
    |> validate_status_hospitalization()
    |> sort_phases_as_needed()
    |> validate_phase_orders()
    |> validate_phase_no_overlap()
  end

  defp validate_clinical_required(changeset) do
    changeset
    |> fetch_field!(:clinical)
    |> case do
      %Clinical{} = clinical ->
        clinical
        |> Clinical.changeset(%{}, %{symptoms_required: true})
        |> case do
          %Ecto.Changeset{valid?: true} ->
            changeset

          %Ecto.Changeset{valid?: false} ->
            add_error(changeset, :clinical, dgettext("errors", "is invalid"))
        end

      nil ->
        add_error(changeset, :clinical, dgettext("errors", "is invalid"))
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
            %Changeset{data: %Phase.Index{}} -> :index
            %Phase.PossibleIndex{type: type} -> {:possible_index, type}
            %Changeset{data: %Phase.PossibleIndex{type: type}} -> {:possible_index, type}
          end
        end)

      if length(unique_phases) == length(keep_phases) do
        []
      else
        [phases: gettext("Case Phase Type must be unique")]
      end
    end)
  end

  defp validate_status_hospitalization(changeset) do
    case {fetch_change(changeset, :status), fetch_change(changeset, :hospitalizations)} do
      {:error, :error} ->
        changeset

      _other ->
        cond do
          Enum.all?(
            fetch_field!(changeset, :hospitalizations),
            &match?(%Hospitalization{start: %Date{}, end: %Date{}}, &1)
          ) ->
            changeset

          fetch_field!(changeset, :status) not in [:done, :canceled] ->
            changeset

          true ->
            add_error(
              changeset,
              :status,
              gettext(
                ~S(If there are open hospitalizations, the status can not be set to "done" / "canceled".)
              )
            )
        end
    end
  end

  defp sort_phases_as_needed(%Changeset{valid?: false} = changeset), do: changeset

  defp sort_phases_as_needed(%Changeset{valid?: true} = changeset) do
    phases = get_field(changeset, :phases)

    sorted_phases =
      Enum.sort_by(
        phases,
        fn
          %Phase{details: %Phase.Index{}, start: start} ->
            {start, :index}

          %Phase{details: %Phase.PossibleIndex{type: type}, start: start} ->
            {start, type}
        end,
        fn
          compare, compare ->
            true

          {date_start, type_a}, {date_start, type_b} ->
            @phase_type_order[type_a] <= @phase_type_order[type_b]

          {_date_a, :index}, {_date_b, _type_b} ->
            false

          {_date_a, _type_a}, {_date_b, :index} ->
            true

          {nil, _type_a}, {%Date{}, _type_b} ->
            true

          {%Date{}, _type_a}, {nil, _type_b} ->
            false

          {%Date{} = date_a, _type_a}, {%Date{} = date_b, _type_b} ->
            Date.compare(date_a, date_b) in [:lt, :eq]
        end
      )

    if sorted_phases != phases do
      put_change(changeset, :phases, sorted_phases)
    else
      changeset
    end
  end

  defp validate_phase_orders(changeset) do
    case {fetch_change(changeset, :status), fetch_change(changeset, :phases)} do
      {:error, :error} ->
        changeset

      _other ->
        cond do
          not Enum.any?(
            fetch_field!(changeset, :phases),
            &match?(%Phase{quarantine_order: nil}, &1)
          ) ->
            changeset

          fetch_field!(changeset, :status) not in [:done, :canceled] ->
            changeset

          true ->
            add_error(
              changeset,
              :status,
              gettext(
                ~S(If there are phases without decided unknown quarantine / isolation orders, the status must not be "done" / "canceled".)
              )
            )
        end
    end
  end

  defp validate_phase_no_overlap(changeset) do
    validate_change(changeset, :phases, fn :phases, phases ->
      phases
      |> Enum.reject(&match?(%Changeset{action: action} when action in [:replace, :delete], &1))
      |> Enum.filter(&fetch_field!(&1, :quarantine_order))
      |> Enum.reject(&is_nil(fetch_field!(&1, :start)))
      |> Enum.reject(&is_nil(fetch_field!(&1, :end)))
      |> Enum.map(&Date.range(fetch_field!(&1, :start), fetch_field!(&1, :end)))
      |> Enum.map(&MapSet.new/1)
      |> Enum.reduce_while(MapSet.new(), fn phase_range, acc ->
        acc
        |> MapSet.intersection(phase_range)
        |> MapSet.size()
        |> Kernel.<=(1)
        |> if do
          {:cont, MapSet.union(acc, phase_range)}
        else
          {:halt, :overlap}
        end
      end)
      |> case do
        :overlap -> [phases: gettext("Phase Quarantine / Isolation Orders must not overlap.")]
        _map -> []
      end
    end)
  end

  @doc """
  This function is used to detect when a phase could have started the earliest.
  This is used to check self service inputs. Tracers are allowed to override.

    Today(Case creation): 11.10.2021
    Test: 10.10.2021
    Symptom-Start(Person in Autotracing): 1.10.2021
    Phase Start: 11.10.2021
    Phase End: 14.10.2021

    If there is no Test-Date then Phase End would be 15.10.2021
  """
  @spec earliest_self_service_phase_start_date(
          case :: t,
          phase_type :: Phase.Index | Phase.PossibleIndex
        ) ::
          {:corrected | :ok, Date.t()}
  def earliest_self_service_phase_start_date(
        %__MODULE__{tests: tests, phases: phases, inserted_at: inserted_at, clinical: clinical} =
          _case,
        phase_type
      ) do
    first_test_date =
      tests
      |> Enum.filter(&match?(%Test{result: :positive}, &1))
      |> Enum.map(&(&1.tested_at || &1.laboratory_reported_at))
      |> Enum.reject(&is_nil/1)
      |> Enum.sort({:asc, Date})
      |> List.first()

    index_phase_start_date =
      Enum.find_value(phases, fn
        %Phase{details: %^phase_type{}, inserted_at: inserted_at} ->
          DateTime.to_date(inserted_at)

        _phase ->
          false
      end)

    phase_start =
      [
        first_test_date,
        index_phase_start_date,
        DateTime.to_date(inserted_at)
      ]
      |> Enum.reject(&is_nil/1)
      |> List.first()

    case clinical do
      %Clinical{symptom_start: %Date{} = symptom_start} ->
        earliest_start_date = Date.add(phase_start, -@max_days_for_phase_start_in_the_past)

        earliest_start_date
        |> Date.compare(symptom_start)
        |> case do
          :eq -> {:ok, symptom_start}
          :gt -> {:corrected, earliest_start_date}
          :lt -> {:ok, symptom_start}
        end

      _clinical ->
        {:ok, phase_start}
    end
  end

  @spec closed?(case :: t) :: boolean
  def closed?(case), do: case.status in [:done, :canceled]

  defimpl Hygeia.Authorization.Resource do
    alias Hygeia.CaseContext.Case
    alias Hygeia.Repo
    alias Hygeia.TenantContext.Tenant
    alias Hygeia.UserContext.User

    @spec preload(resource :: Case.t()) :: Case.t()
    def preload(resource), do: Repo.preload(resource, :tenant)

    @spec authorized?(
            resource :: Case.t(),
            action ::
              :details | :partial_details | :create | :list | :update | :delete | :auto_tracing,
            user :: :anonymous | User.t() | Person.t(),
            meta :: %{atom() => term}
          ) :: boolean
    def authorized?(_case, action, :anonymous, _meta)
        when action in [
               :list,
               :create,
               :details,
               :partial_details,
               :update,
               :delete,
               :auto_tracing
             ],
        do: false

    def authorized?(
          %Case{person_uuid: person_uuid},
          action,
          %Person{uuid: person_uuid},
          _meta
        )
        when action in [:partial_details, :auto_tracing],
        do: true

    def authorized?(_case, action, %Person{}, _meta)
        when action in [
               :list,
               :create,
               :details,
               :partial_details,
               :update,
               :delete,
               :auto_tracing
             ],
        do: false

    def authorized?(
          %Case{tracer_uuid: tracer_uuid},
          action,
          %User{uuid: tracer_uuid} = user,
          _meta
        )
        when action in [:details, :partial_details, :auto_tracing],
        do: User.has_role?(user, :tracer, :any)

    def authorized?(
          %Case{supervisor_uuid: supervisor_uuid},
          action,
          %User{uuid: supervisor_uuid} = user,
          _meta
        )
        when action in [:details, :partial_details, :auto_tracing],
        do: User.has_role?(user, :supervisor, :any)

    def authorized?(%Case{tenant: %Tenant{iam_domain: nil}}, action, user, _meta)
        when action in [:details, :partial_details, :versioning, :update, :delete, :auto_tracing],
        do:
          Enum.any?(
            [:super_user, :supervisor, :admin],
            &User.has_role?(user, &1, :any)
          )

    def authorized?(%Case{tenant_uuid: tenant_uuid}, action, user, _meta)
        when action in [:details, :partial_details, :versioning, :auto_tracing],
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
