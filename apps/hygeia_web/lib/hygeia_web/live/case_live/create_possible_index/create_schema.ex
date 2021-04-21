defmodule HygeiaWeb.CaseLive.CreatePossibleIndex.CreateSchema do
  @moduledoc false

  use Hygeia, :model

  import HygeiaWeb.CaseLive.Create.CreateSchema
  import HygeiaGettext

  alias Hygeia.CaseContext
  alias Hygeia.CaseContext.Case
  alias Hygeia.CaseContext.Case.Phase.PossibleIndex.Type
  alias Hygeia.CaseContext.Person
  alias Hygeia.CaseContext.PossibleIndexSubmission
  alias Hygeia.CaseContext.Transmission
  alias Hygeia.CaseContext.Transmission.InfectionPlace
  alias Hygeia.TenantContext.Tenant
  alias Hygeia.UserContext.User
  alias HygeiaWeb.CaseLive.Create.CreatePersonSchema

  embedded_schema do
    belongs_to :default_tenant, Tenant, references: :uuid, foreign_key: :default_tenant_uuid
    belongs_to :default_supervisor, User, references: :uuid, foreign_key: :default_supervisor_uuid
    belongs_to :default_tracer, User, references: :uuid, foreign_key: :default_tracer_uuid

    field :type, Type
    field :type_other, :string

    field :date, :date
    field :propagator_ism_id, :string
    field :propagator_internal, :boolean

    field :send_confirmation_sms, :boolean, default: false
    field :send_confirmation_email, :boolean, default: false
    field :directly_close_cases, :boolean, default: false
    field :copy_address_from_propagator, :boolean, default: false

    belongs_to :propagator_case, Case, references: :uuid, foreign_key: :propagator_case_uuid

    belongs_to :possible_index_submission, PossibleIndexSubmission,
      references: :uuid,
      foreign_key: :possible_index_submission_uuid

    embeds_one :infection_place, InfectionPlace

    embeds_many :people, CreatePersonSchema, on_replace: :delete
  end

  @spec changeset(schema :: %__MODULE__{}, attrs :: Hygeia.ecto_changeset_params()) ::
          Ecto.Changeset.t()
  def changeset(schema, attrs \\ %{}) do
    schema
    |> cast(attrs, [
      :default_tenant_uuid,
      :default_supervisor_uuid,
      :default_tracer_uuid,
      :type,
      :type_other,
      :date,
      :propagator_case_uuid,
      :propagator_internal,
      :propagator_ism_id,
      :send_confirmation_sms,
      :send_confirmation_email,
      :directly_close_cases,
      :copy_address_from_propagator,
      :possible_index_submission_uuid
    ])
    |> cast_embed(:people, required: true)
    |> cast_embed(:infection_place, required: true)
    |> validate_changeset()
  end

  @spec validate_changeset(changeset :: Ecto.Changeset.t()) :: Ecto.Changeset.t()
  def validate_changeset(changeset) do
    people =
      changeset
      |> drop_empty_rows()
      |> fetch_field!(:people)

    changeset =
      changeset
      |> validate_required([
        :type,
        :date
      ])
      |> validate_date()
      |> validate_type_other()
      |> Transmission.validate_case(
        :propagator_internal,
        :propagator_ism_id,
        :propagator_case_uuid
      )
      |> drop_multiple_empty_rows()
      |> CreatePersonSchema.detect_duplicates()

    if Enum.any?(people, &match?(%CreatePersonSchema{tenant_uuid: nil}, &1)) do
      validate_required(changeset, [:default_tenant_uuid])
    else
      changeset
    end
  end

  @spec drop_empty_rows(changeset :: Ecto.Changeset.t()) :: Ecto.Changeset.t()
  def drop_empty_rows(changeset) do
    put_embed(
      changeset,
      :people,
      changeset
      |> get_change(:people, [])
      |> Enum.reject(&is_empty?(&1, [:search_params_hash, :suspected_duplicate_uuids]))
    )
  end

  defp validate_type_other(changeset) do
    changeset
    |> fetch_field!(:type)
    |> case do
      :other -> validate_required(changeset, [:type_other])
      _defined -> put_change(changeset, :type_other, nil)
    end
  end

  defp validate_date(changeset) do
    validate_change(changeset, :date, fn :date, value ->
      diff = Date.diff(Date.utc_today(), value)

      # TODO: Correct Validation Rules
      # diff > 10 ->
      #   [{:date, dgettext("errors", "date must not be older than 10 days")}]

      if diff < 0 do
        [{:date, dgettext("errors", "date must not be in the future")}]
      else
        []
      end
    end)
  end

  # credo:disable-for-next-line Credo.Check.Design.DuplicatedCode
  defp drop_multiple_empty_rows(changeset) do
    put_embed(
      changeset,
      :people,
      changeset
      |> get_change(:people, [])
      |> Enum.sort_by(&is_empty?(&1, [:search_params_hash, :suspected_duplicate_uuids]))
      |> Enum.map(&{&1, is_empty?(&1, [:search_params_hash, :suspected_duplicate_uuids])})
      |> Enum.chunk_every(2, 1)
      |> Enum.map(fn
        [{entry, false}] -> [entry, CreatePersonSchema.changeset(%CreatePersonSchema{}, %{})]
        [{entry, true}] -> [entry]
        [{_entry, true}, {_next_entry, true}] -> []
        [{entry, _empty}, {_next_entry, _next_empty}] -> [entry]
      end)
      |> List.flatten()
      |> case do
        [] -> [CreatePersonSchema.changeset(%CreatePersonSchema{}, %{})]
        [_entry | _other_entries] = other -> other
      end
    )
  end

  @spec upsert_case(
          {create_person_schema :: %CreatePersonSchema{}, person :: Person.t()},
          schema :: %__MODULE__{}
        ) :: Case.t()
  def upsert_case(
        {%CreatePersonSchema{
           accepted_duplicate_case_uuid: duplicate_case_uuid,
           tracer_uuid: tracer_uuid,
           supervisor_uuid: supervisor_uuid,
           ism_case_id: ism_case_id,
           ism_report_id: ism_report_id
         }, person},
        %__MODULE__{
          default_tracer_uuid: default_tracer_uuid,
          default_supervisor_uuid: default_supervisor_uuid,
          type: global_type,
          type_other: global_type_other,
          directly_close_cases: directly_close_cases,
          date: date
        }
      ) do
    changeset =
      duplicate_case_uuid
      |> case do
        nil ->
          person
          |> CaseContext.change_new_case(%{})
          |> Map.put(:errors, [])
          |> Map.put(:valid?, true)

        uuid ->
          uuid |> CaseContext.get_case!() |> CaseContext.change_case()
      end
      |> merge_phases(date, global_type, global_type_other)
      |> merge_status(directly_close_cases)
      |> merge_assignee(:tracer_uuid, tracer_uuid, default_tracer_uuid)
      |> merge_assignee(:supervisor_uuid, supervisor_uuid, default_supervisor_uuid)
      |> merge_external_reference(:ism_case, ism_case_id)
      |> merge_external_reference(:ism_report, ism_report_id)

    {:ok, case} =
      case duplicate_case_uuid do
        nil -> CaseContext.create_case(changeset)
        _id -> CaseContext.update_case(changeset)
      end

    case
  end

  defp merge_phases(changeset, date, global_type, global_type_other) do
    existing_phases =
      changeset
      |> Ecto.Changeset.fetch_field!(:phases)
      # Drop Empty Phases for Create Form
      |> Enum.reject(&match?(%Case.Phase{details: nil}, &1))

    existing_phases
    |> Enum.find(&match?(%Case.Phase{details: %Case.Phase.PossibleIndex{type: ^global_type}}, &1))
    |> case do
      nil ->
        if global_type in [:contact_person, :travel] do
          {start_date, end_date} = phase_dates(date)
          old_phase_end_date = Date.add(start_date, -1)

          status_changed_phases =
            Enum.map(existing_phases, fn
              %Case.Phase{quarantine_order: true, start: old_phase_start} = phase ->
                if Date.compare(old_phase_start, old_phase_end_date) == :lt do
                  %Case.Phase{
                    phase
                    | end: Date.add(start_date, -1),
                      send_automated_close_email: false
                  }
                else
                  %Case.Phase{phase | quarantine_order: false}
                end

              %Case.Phase{quarantine_order: quarantine_order} = phase
              when quarantine_order in [false, nil] ->
                phase
            end)

          changeset
          |> Ecto.Changeset.put_embed(
            :phases,
            status_changed_phases ++
              [
                %Case.Phase{
                  details: %Case.Phase.PossibleIndex{
                    type: global_type,
                    type_other: global_type_other
                  },
                  quarantine_order: true,
                  start: start_date,
                  end: end_date
                }
              ]
          )
          |> Ecto.Changeset.put_change(:status, :first_contact)
        else
          changeset
          |> Ecto.Changeset.put_embed(
            :phases,
            existing_phases ++
              [
                %Case.Phase{
                  details: %Case.Phase.PossibleIndex{
                    type: global_type,
                    type_other: global_type_other
                  }
                }
              ]
          )
          |> Ecto.Changeset.put_change(:status, :first_contact)
        end

      %Case.Phase{} ->
        changeset
    end
  end

  defp merge_status(changeset, directly_close_cases)
  defp merge_status(changeset, true), do: Ecto.Changeset.put_change(changeset, :status, :done)
  defp merge_status(changeset, false), do: changeset

  defp phase_dates(contact_date) do
    case contact_date do
      nil ->
        {nil, nil}

      %Date{} = contact_date ->
        start_date = contact_date
        end_date = Date.add(start_date, 9)

        start_date =
          if Date.compare(start_date, Date.utc_today()) == :lt do
            Date.utc_today()
          else
            start_date
          end

        end_date =
          if Date.compare(end_date, Date.utc_today()) == :lt do
            Date.utc_today()
          else
            end_date
          end

        {start_date, end_date}
    end
  end

  @spec create_transmission(case :: Case.t(), schema :: %__MODULE__{}) :: Transmission.t()
  def create_transmission(case, %__MODULE__{
        date: date,
        infection_place: infection_place,
        propagator_internal: propagator_internal,
        propagator_ism_id: propagator_ism_id,
        propagator_case_uuid: propagator_case_uuid
      }) do
    {:ok, transmission} =
      CaseContext.create_transmission(%{
        date: date,
        recipient_internal: true,
        recipient_case_uuid: case.uuid,
        infection_place: unpack(infection_place),
        propagator_internal: propagator_internal,
        propagator_ism_id: propagator_ism_id,
        propagator_case_uuid: propagator_case_uuid
      })

    transmission
  end

  defp unpack(struct) when is_struct(struct) do
    struct
    |> Map.from_struct()
    |> Enum.map(fn {key, value} -> {key, unpack(value)} end)
    |> Map.new()
  end

  defp unpack(other), do: other
end
