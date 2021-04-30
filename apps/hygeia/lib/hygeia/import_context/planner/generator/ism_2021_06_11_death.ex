# credo:disable-for-this-file Credo.Check.Readability.ModuleNames
defmodule Hygeia.ImportContext.Planner.Generator.ISM_2021_06_11_Death do
  @moduledoc false

  use Hygeia.ImportContext.Planner.Generator

  alias Hygeia.ImportContext.Planner.Action.PatchPhaseDeath
  alias Hygeia.ImportContext.Planner.Generator.ISM_2021_06_11
  alias Hygeia.Repo
  alias Hygeia.TenantContext

  @fields Map.new(
            %{
              case_id: "Fall ID",
              report_id: "Meldung ID",
              first_name: "Vorname",
              last_name: "Nachname",
              phone: "Telefon",
              patient_id: "Patient ID",
              tenant_short_name: "Fallkanton",
              birth_date: "Geburtsdatum",
              sex: "Geschlecht",
              address: "Strasse",
              zip: "PLZ",
              place: "Wohnort",
              country: "Wohnsitzland"
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
      &patch_phase_death/3,
      ISM_2021_06_11.patch_extenal_references(@fields),
      &ISM_2021_06_11.save/3
    ]

  defp patch_phase_death(_row, _params, _preceeding_steps), do: {:certain, %PatchPhaseDeath{}}
end
