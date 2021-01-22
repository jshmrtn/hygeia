defmodule HygeiaWeb.CaseLive.CreateIndex.CreateSchema do
  @moduledoc false

  use Hygeia, :model

  import HygeiaWeb.CaseLive.Create.CreateSchema

  alias Hygeia.CaseContext
  alias Hygeia.CaseContext.Case
  alias Hygeia.CaseContext.Person
  alias Hygeia.TenantContext.Tenant
  alias Hygeia.UserContext.User
  alias HygeiaWeb.CaseLive.Create.CreatePersonSchema

  embedded_schema do
    belongs_to :default_tenant, Tenant, references: :uuid, foreign_key: :default_tenant_uuid
    belongs_to :default_supervisor, User, references: :uuid, foreign_key: :default_supervisor_uuid
    belongs_to :default_tracer, User, references: :uuid, foreign_key: :default_tracer_uuid

    embeds_many :people, CreatePersonSchema, on_replace: :delete
  end

  @spec changeset(schema :: %__MODULE__{}, attrs :: Hygeia.ecto_changeset_params()) ::
          Ecto.Changeset.t()
  def changeset(schema, attrs \\ %{}) do
    schema
    |> cast(attrs, [
      :default_tenant_uuid,
      :default_supervisor_uuid,
      :default_tracer_uuid
    ])
    |> cast_embed(:people, required: true)
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
      |> drop_multiple_empty_rows()
      |> CreatePersonSchema.detect_duplicates()

    changeset =
      if Enum.any?(people, &match?(%CreatePersonSchema{tenant_uuid: nil}, &1)) do
        validate_required(changeset, [:default_tenant_uuid])
      else
        changeset
      end

    changeset =
      if Enum.any?(people, &match?(%CreatePersonSchema{supervisor_uuid: nil}, &1)) do
        validate_required(changeset, [:default_supervisor_uuid])
      else
        changeset
      end

    if Enum.any?(people, &match?(%CreatePersonSchema{tracer_uuid: nil}, &1)) do
      validate_required(changeset, [:default_tracer_uuid])
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
           clinical: clinical,
           ism_case_id: ism_case_id,
           ism_report_id: ism_report_id
         }, person},
        %__MODULE__{
          default_tracer_uuid: default_tracer_uuid,
          default_supervisor_uuid: default_supervisor_uuid
        }
      ) do
    changeset =
      duplicate_case_uuid
      |> case do
        nil ->
          person
          |> CaseContext.create_case_changeset(%{})
          |> Map.put(:errors, [])
          |> Map.put(:valid?, true)

        uuid ->
          uuid |> CaseContext.get_case!() |> CaseContext.change_case()
      end
      |> merge_phases()
      |> merge_clinical(clinical)
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

  defp merge_phases(changeset) do
    existing_phases =
      changeset
      |> Ecto.Changeset.fetch_field!(:phases)
      # Drop Empty Phases for Create Form
      |> Enum.reject(&match?(%Case.Phase{details: nil}, &1))

    existing_phases
    |> Enum.find(&match?(%Case.Phase{details: %Case.Phase.Index{}}, &1))
    |> case do
      nil ->
        status_changed_phases =
          Enum.map(existing_phases, fn
            %Case.Phase{details: %Case.Phase.PossibleIndex{} = possible_index} = phase ->
              %Case.Phase{
                phase
                | details: %Case.Phase.PossibleIndex{
                    possible_index
                    | end_reason: :converted_to_index
                  },
                  send_automated_close_email: false
              }
          end)

        changeset
        |> Ecto.Changeset.put_embed(
          :phases,
          status_changed_phases ++ [%Case.Phase{details: %Case.Phase.Index{}}]
        )
        |> Ecto.Changeset.put_change(:status, :first_contact)

      %Case.Phase{} ->
        changeset
    end
  end

  defp merge_clinical(changeset, clinical) do
    Ecto.Changeset.put_embed(
      changeset,
      :clinical,
      changeset
      |> Ecto.Changeset.fetch_field!(:clinical)
      |> case do
        nil -> %Case.Clinical{}
        %Case.Clinical{} = clinical -> clinical
      end
      |> Case.Clinical.merge(clinical)
    )
  end
end
