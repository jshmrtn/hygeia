# credo:disable-for-this-file Credo.Check.Readability.ModuleNames
defmodule Hygeia.ImportContext.Planner.Generator.ISM_2021_06_11_DeathTest do
  @moduledoc false

  use ExUnit.Case
  use Hygeia.DataCase

  alias Hygeia.CaseContext.Address
  alias Hygeia.CaseContext.Case
  alias Hygeia.CaseContext.ExternalReference
  alias Hygeia.CaseContext.Person
  alias Hygeia.ImportContext
  alias Hygeia.ImportContext.Import
  alias Hygeia.ImportContext.Planner
  alias Hygeia.ImportContext.Row
  alias Hygeia.TenantContext.Tenant

  @moduletag origin: :test
  @moduletag originator: :noone

  @mime MIME.type("xlsx")
  @path Application.app_dir(:hygeia, "priv/test/import/example_ism_2021_06_11_death.xlsx")
  @external_resource @path

  setup do
    tenant_ar = tenant_fixture(%{subdivision: "AR", country: "CH"})
    tenant_sg = tenant_fixture(%{subdivision: "SG", country: "CH"})

    {:ok, import} =
      ImportContext.create_import(tenant_ar, @mime, @path, %{
        type: :ism_2021_06_11_death
      })

    import = Repo.preload(import, :rows)

    {:ok, import: import, tenant_ar: tenant_ar, tenant_sg: tenant_sg}
  end

  test "runs correct plan for new case", %{
    import: %Import{rows: rows},
    tenant_sg: %Tenant{uuid: tenant_sg_uuid}
  } do
    row = Enum.find(rows, &(&1.data["Fall ID"] == 2_327_500))

    {true, action_plan_suggestion} = Planner.generate_action_plan_suggestion(row)

    action_plan = Enum.map(action_plan_suggestion, &elem(&1, 1))

    assert {:ok,
            %{
              row: row,
              case: case,
              person: person
            }} = Planner.execute(action_plan, row)

    assert %Row{
             case_uuid: case_uuid,
             status: :resolved
           } = row

    assert %Case{
             uuid: ^case_uuid,
             person_uuid: person_uuid,
             external_references: [%ExternalReference{type: :ism_case, value: "2327500"}],
             phases: [%Case.Phase{details: %Case.Phase.Index{end_reason: :death}}],
             tenant_uuid: ^tenant_sg_uuid
           } = case

    assert %Person{
             uuid: ^person_uuid,
             external_references: [%ExternalReference{type: :ism_patient, value: "1709206"}],
             last_name: "Müller",
             first_name: "Peter",
             birth_date: ~D[1930-03-04],
             sex: :male,
             address: %Address{
               address: "Hofgasse 2",
               zip: "9014",
               place: "St. Gallen",
               country: "CH"
             },
             tenant_uuid: ^tenant_sg_uuid
           } = person
  end
end
