# credo:disable-for-this-file Credo.Check.Readability.ModuleNames
defmodule Hygeia.ImportContext.Planner.Generator.ISM_2021_06_11_Test do
  @moduledoc false

  use Hygeia.ImportContext.Planner.Generator

  alias Hygeia.ImportContext.Planner.Generator.ISM_2021_06_11
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
              tenant_short_name: "Zuständiger Kanton",
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
      ISM_2021_06_11.select_case(@fields),
      &ISM_2021_06_11.patch_phase/3,
      ISM_2021_06_11.patch_person(@fields),
      ISM_2021_06_11.patch_tests(@fields),
      &ISM_2021_06_11.patch_assignee/3,
      &ISM_2021_06_11.patch_status/3,
      ISM_2021_06_11.patch_extenal_references(@fields),
      ISM_2021_06_11.add_note(),
      &ISM_2021_06_11.save/3
    ]
end
