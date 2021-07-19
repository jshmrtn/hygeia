# credo:disable-for-this-file Credo.Check.Readability.ModuleNames
defmodule Hygeia.ImportContext.Planner.Generator.ISM_2021_06_11_TestTest do
  @moduledoc false

  use ExUnit.Case
  use Hygeia.DataCase

  alias Hygeia.CaseContext.Address
  alias Hygeia.CaseContext.Case
  alias Hygeia.CaseContext.Entity
  alias Hygeia.CaseContext.ExternalReference
  alias Hygeia.CaseContext.Person
  alias Hygeia.CaseContext.Test
  alias Hygeia.ImportContext
  alias Hygeia.ImportContext.Import
  alias Hygeia.ImportContext.Planner
  alias Hygeia.ImportContext.Row
  alias Hygeia.TenantContext.Tenant

  @moduletag origin: :test
  @moduletag originator: :noone

  @mime MIME.type("xlsx")
  @path Application.app_dir(:hygeia, "priv/test/import/example_ism_2021_06_11_test.xlsx")
  @external_resource @path

  setup do
    tenant_ar = tenant_fixture(%{subdivision: "AR", country: "CH"})
    tenant_sg = tenant_fixture(%{subdivision: "SG", country: "CH"})

    {:ok, import} =
      ImportContext.create_import(tenant_ar, @mime, @path, %{
        type: :ism_2021_06_11_test
      })

    import = Repo.preload(import, :rows)

    {:ok, import: import, tenant_ar: tenant_ar, tenant_sg: tenant_sg}
  end

  test "runs correct plan for new case", %{
    import: %Import{rows: [row | _others]},
    tenant_sg: %Tenant{uuid: tenant_sg_uuid}
  } do
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
             external_references: [
               %ExternalReference{type: :ism_case, value: "2182953"},
               %ExternalReference{type: :ism_report, value: "1794060"}
             ],
             phases: [%Case.Phase{details: %Case.Phase.Index{}}],
             tenant_uuid: ^tenant_sg_uuid,
             tests: [
               %Test{
                 kind: :pcr,
                 laboratory_reported_at: ~D[2021-03-24],
                 reference: "21 3240 0755",
                 reporting_unit: %Entity{
                   address: %Address{
                     address: "Lagerstrasse 30",
                     country: "CH",
                     place: "Buchs SG",
                     zip: "9470"
                   },
                   division: "Buchs",
                   name: "Labormedizinisches Zentrum Dr. Risch"
                 },
                 result: :inconclusive,
                 sponsor: %Hygeia.CaseContext.Entity{
                   address: %Hygeia.CaseContext.Address{
                     address: "Chnoblisbüel 1",
                     country: "CH",
                     place: "Walenstadtberg",
                     subdivision: nil,
                     zip: "8881"
                   },
                   division: "Rehazentrum Walenstadtberg",
                   name: "Kliniken Valens",
                   person_first_name: nil,
                   person_last_name: nil
                 },
                 tested_at: ~D[2021-03-24]
               }
             ]
           } = case

    assert %Person{
             uuid: ^person_uuid,
             external_references: [%ExternalReference{type: :ism_patient, value: "1561000"}],
             last_name: "Licht",
             first_name: "Laura",
             birth_date: ~D[1943-09-30],
             sex: :female,
             address: %Address{
               address: "Musterstraße 10",
               zip: "9443",
               place: "Widnau",
               country: "CH"
             },
             tenant_uuid: ^tenant_sg_uuid
           } = person
  end
end
