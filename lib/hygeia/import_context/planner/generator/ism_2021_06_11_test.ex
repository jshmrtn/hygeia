# credo:disable-for-this-file Credo.Check.Readability.ModuleNames
defmodule Hygeia.ImportContext.Planner.Generator.ISM_2021_06_11_Test do
  @moduledoc false

  use Hygeia.ImportContext.Planner.Generator

  import HygeiaGettext

  alias Hygeia.AutoTracingContext.AutoTracing
  alias Hygeia.CaseContext.Case
  alias Hygeia.ImportContext.Planner
  alias Hygeia.ImportContext.Planner.Action.CreateAutoTracing
  alias Hygeia.ImportContext.Planner.Generator.ISM_2021_06_11
  alias Hygeia.ImportContext.Row

  alias Hygeia.Repo
  alias Hygeia.TenantContext

  @fields Map.new(
            %{
              case_id: "Fall ID",
              report_id: "Meldung ID",
              first_name: "Patient Vorname",
              last_name: "Patient Nachname",
              phone: "Patient Telefon",
              email: "E-Mail",
              patient_id: "Patient ID",
              tenant_subdivision: "Zuständiger Kanton",
              birth_date: "Patient Geburtsdatum",
              sex: "Patient Geschlecht",
              address: "Patient Strasse",
              zip: "Patient PLZ",
              place: "Patient Wohnort",
              subdivision: "Patient Kanton",
              country: "Wohnsitzland",
              tested_at: "Entnahmedatum",
              laboratory_reported_at: "Testdatum",
              test_result: "Testresultat",
              test_kind: "Nachweismethode",
              test_reference: "Test ID/Referenz",
              reporting_unit_name: "Meldeeinheit Institution",
              reporting_unit_division: "Meldeeinheit Abteilung/Institut",
              reporting_unit_person_first_name: "Meldeeinheit Vorname",
              reporting_unit_person_last_name: "Meldeeinheit Nachname",
              reporting_unit_address: "Meldeeinheit Strasse",
              reporting_unit_zip: "Meldeeinheit PLZ",
              reporting_unit_place: "Meldeeinheit Ort",
              sponsor_name: "Auftraggeber Institution",
              sponsor_division: "Auftraggeber Abteilung/Institut",
              sponsor_person_first_name: "Auftraggeber Vorname",
              sponsor_person_last_name: "Auftraggeber Nachname",
              sponsor_address: "Auftraggeber Strasse",
              sponsor_zip: "Auftraggeber PLZ",
              sponsor_place: "Auftraggeber Ort",
              mutation_ism_code: "Typisierung Code"
            },
            &{elem(&1, 0), &1 |> elem(1) |> String.downcase() |> String.trim()}
          )

  @impl Hygeia.ImportContext.Planner.Generator
  def before_action_plan(row, params),
    do:
      {Repo.preload(row, :tenant),
       Map.merge(params, %{
         tenants: TenantContext.list_tenants(),
         predecessor: Repo.preload(params.predecessor, case: [person: []])
       })}

  @impl Hygeia.ImportContext.Planner.Generator
  def action_plan_steps,
    do: [
      ISM_2021_06_11.select_tenant(@fields),
      ISM_2021_06_11.select_case(@fields, @fields.laboratory_reported_at),
      &ISM_2021_06_11.patch_phase/3,
      ISM_2021_06_11.patch_person(@fields),
      ISM_2021_06_11.patch_tests(@fields),
      &ISM_2021_06_11.patch_assignee/3,
      &ISM_2021_06_11.patch_status/3,
      ISM_2021_06_11.patch_extenal_references(@fields),
      ISM_2021_06_11.add_note(),
      create_auto_tracing(),
      &ISM_2021_06_11.save/3
    ]

  @impl Hygeia.ImportContext.Planner.Generator
  def id_fields, do: [@fields.case_id]

  @impl Hygeia.ImportContext.Planner.Generator
  def list_fields, do: [@fields.case_id, @fields.first_name, @fields.last_name]

  @impl Hygeia.ImportContext.Planner.Generator
  # credo:disable-for-next-line Credo.Check.Refactor.ABCSize
  def display_field_grouping,
    do: %{
      pgettext("ISM 2021-06-11 Test Field Group", "References") =>
        MapSet.new([
          @fields.case_id,
          @fields.report_id,
          @fields.patient_id,
          @fields.test_reference
        ]),
      pgettext("ISM 2021-06-11 Test Field Group", "Personal") =>
        MapSet.new([
          @fields.first_name,
          @fields.last_name,
          @fields.phone,
          @fields.email,
          @fields.birth_date,
          @fields.sex,
          @fields.place,
          @fields.zip,
          @fields.address,
          @fields.subdivision,
          @fields.country,
          @fields.tenant_subdivision
        ]),
      pgettext("ISM 2021-06-11 Test Field Group", "Test") =>
        MapSet.new([
          @fields.tested_at,
          @fields.laboratory_reported_at,
          @fields.test_result,
          @fields.test_kind,
          @fields.reporting_unit_name,
          @fields.reporting_unit_division,
          @fields.reporting_unit_person_first_name,
          @fields.reporting_unit_person_last_name,
          @fields.reporting_unit_address,
          @fields.reporting_unit_zip,
          @fields.reporting_unit_place,
          @fields.sponsor_name,
          @fields.sponsor_division,
          @fields.sponsor_person_first_name,
          @fields.sponsor_person_last_name,
          @fields.sponsor_address,
          @fields.sponsor_zip,
          @fields.sponsor_place,
          @fields.mutation_ism_code
        ])
    }

  @spec create_auto_tracing ::
          (row :: Row.t(),
           params :: Planner.Generator.params(),
           preceeding_action_plan :: [Planner.Action.t()] ->
             {Planner.certainty(), Planner.Action.t()})
  defp create_auto_tracing do
    fn %Row{}, _params, preceeding_steps ->
      {_certainty,
       %Planner.Action.SelectCase{case: case, suppress_quarantine: suppress_quarantine}} =
        Enum.find(preceeding_steps, &match?({_certainty, %Planner.Action.SelectCase{}}, &1))

      {_certainty, %Planner.Action.PatchPhases{action: patch_phase_action}} =
        Enum.find(preceeding_steps, &match?({_certainty, %Planner.Action.PatchPhases{}}, &1))

      action =
        cond do
          suppress_quarantine -> :skip
          patch_phase_action == :skip -> :skip
          match?(%Case{auto_tracing: %AutoTracing{}}, case) -> :skip
          true -> :create
        end

      {:certain, %CreateAutoTracing{action: action}}
    end
  end
end
