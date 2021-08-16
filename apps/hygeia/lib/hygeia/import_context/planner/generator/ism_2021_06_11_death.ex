# credo:disable-for-this-file Credo.Check.Readability.ModuleNames
defmodule Hygeia.ImportContext.Planner.Generator.ISM_2021_06_11_Death do
  @moduledoc false

  use Hygeia.ImportContext.Planner.Generator

  import HygeiaGettext

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
              tenant_subdivision: "Fallkanton",
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
      ISM_2021_06_11.add_note(),
      &ISM_2021_06_11.save/3
    ]

  @impl Hygeia.ImportContext.Planner.Generator
  def id_fields, do: [@fields.case_id]

  @impl Hygeia.ImportContext.Planner.Generator
  def list_fields, do: [@fields.case_id, @fields.first_name, @fields.last_name]

  @impl Hygeia.ImportContext.Planner.Generator
  def display_field_grouping,
    do: %{
      pgettext("ISM 2021-06-11 Death Field Group", "References") =>
        MapSet.new([
          @fields.case_id,
          @fields.report_id,
          @fields.patient_id
        ]),
      pgettext("ISM 2021-06-11 Death Field Group", "Personal") =>
        MapSet.new([
          @fields.first_name,
          @fields.last_name,
          @fields.phone,
          @fields.birth_date,
          @fields.sex,
          @fields.place,
          @fields.country,
          @fields.tenant_subdivision,
          @fields.address,
          @fields.zip
        ])
    }

  defp patch_phase_death(_row, _params, _preceeding_steps), do: {:certain, %PatchPhaseDeath{}}
end
