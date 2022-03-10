# credo:disable-for-this-file Credo.Check.Readability.ModuleNames
# credo:disable-for-this-file Credo.Check.Design.DuplicatedCode
defmodule Hygeia.ImportContext.Planner.Generator.ISM_2021_06_11_TestTest do
  @moduledoc false

  use ExUnit.Case
  use Hygeia.DataCase

  alias Hygeia.CaseContext
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
  alias Hygeia.TenantContext
  alias Hygeia.TenantContext.Tenant

  @moduletag origin: :test
  @moduletag originator: :noone

  @mime MIME.type("xlsx")
  @path Application.app_dir(:hygeia, "priv/test/import/example_ism_2021_06_11_test.xlsx")
  @external_resource @path

  setup tags do
    tenant_ar =
      tenant_fixture(%{subdivision: "AR", country: "CH", iam_domain: "ar.covid19-tracing.ch"})

    tenant_sg =
      tenant_fixture(%{subdivision: "SG", country: "CH", iam_domain: "sg.covid19-tracing.ch"})

    tenant_for_import =
      Enum.find(TenantContext.list_tenants(), &(&1.subdivision == tags[:use_tenant] || "SG"))

    {:ok, import} =
      ImportContext.create_import(tenant_for_import, @mime, @path, %{
        type: :ism_2021_06_11_test
      })

    import = Repo.preload(import, :rows)

    {:ok, import: import, tenant_ar: tenant_ar, tenant_sg: tenant_sg}
  end

  test "runs correct plan for new case", %{
    import: %Import{rows: rows},
    tenant_sg: %Tenant{uuid: tenant_sg_uuid}
  } do
    row = Enum.find(rows, &(&1.data["Meldung ID"] == 1_794_060))

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
             contact_methods: [
               %Person.ContactMethod{type: :mobile, value: "+41 78 123 45 67"},
               %Person.ContactMethod{type: :email, value: "test@example.com"}
             ],
             tenant_uuid: ^tenant_sg_uuid
           } = person
  end

  test "runs correct plan for existing case", %{
    import: %Import{rows: rows},
    tenant_sg: %Tenant{uuid: tenant_sg_uuid} = tenant_sg
  } do
    row = Enum.find(rows, &(&1.data["Meldung ID"] == 1_794_060))

    person =
      person_fixture(tenant_sg, %{
        last_name: "Muster",
        first_name: "Max",
        external_references: [%{type: :ism_patient, value: "1673735"}]
      })

    case =
      case_fixture(
        person,
        user_fixture(%{iam_sub: Ecto.UUID.generate()}),
        user_fixture(%{iam_sub: Ecto.UUID.generate()}),
        %{
          external_references: [
            %{type: :ism_case, value: "2182953"},
            %{type: :ism_report, value: "1794060"}
          ],
          phases: [
            %{
              details: %{
                __type__: :possible_index,
                type: :contact_person
              },
              start: ~D[2021-03-24],
              end: ~D[2021-03-25],
              inserted_at: ~N[2021-03-25 08:00:00],
              quarantine_order: true
            }
          ],
          inserted_at: ~N[2021-03-25 08:00:00],
          tests: [],
          clinical: %{}
        }
      )

    case_uuid = case.uuid

    {true, action_plan_suggestion} = Planner.generate_action_plan_suggestion(row)

    action_plan = Enum.map(action_plan_suggestion, &elem(&1, 1))

    assert {:ok,
            %{
              row: row,
              case: case,
              person: person
            }} = Planner.execute(action_plan, row)

    assert %Row{
             case_uuid: ^case_uuid,
             status: :resolved
           } = row

    assert %Case{
             uuid: ^case_uuid,
             person_uuid: person_uuid,
             external_references: [
               %ExternalReference{type: :ism_case, value: "2182953"},
               %ExternalReference{type: :ism_report, value: "1794060"}
             ],
             phases: [
               %Case.Phase{details: %Case.Phase.PossibleIndex{end_reason: :converted_to_index}},
               %Case.Phase{details: %Case.Phase.Index{}}
             ],
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
             external_references: [%ExternalReference{type: :ism_patient, value: "1673735"}],
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

  test "input_needed when invalid email and country/subdivision combination", %{
    import: %Import{rows: rows}
  } do
    row = Enum.find(rows, &(&1.data["Meldung ID"] == 1_794_060))

    row = %{
      row
      | data: %{
          row.data
          | "E-Mail" => "invalid email",
            "Patient Kanton" => "SG",
            "Wohnsitzland" => "DE",
            "Patient Telefon" => "invalid phone"
        }
    }

    assert {false,
            [
              {:uncertain, _choose_tenant},
              {:certain, _select_case},
              {:certain, _patch_phases},
              {:input_needed,
               %Planner.Action.PatchPerson{invalid_changes: [:subdivision, :email, :phone]}}
            ]} = Planner.generate_action_plan_suggestion(row)
  end

  @tag use_tenant: "AR"
  test "warns when using the wrong tenant", %{
    import: %Import{rows: rows},
    tenant_sg: %Tenant{uuid: tenant_sg_uuid}
  } do
    row = Enum.find(rows, &(&1.data["Meldung ID"] == 1_794_060))

    assert {true,
            [
              {:uncertain, %Planner.Action.ChooseTenant{tenant: %Tenant{uuid: ^tenant_sg_uuid}}}
              | _others
            ]} = Planner.generate_action_plan_suggestion(row)
  end

  test "input needed for same row and deleted case", %{
    import: %Import{rows: rows},
    tenant_sg: tenant_sg
  } do
    row = Enum.find(rows, &(&1.data["Meldung ID"] == 1_794_060))
    {true, action_plan_suggestion} = Planner.generate_action_plan_suggestion(row)

    action_plan = Enum.map(action_plan_suggestion, &elem(&1, 1))

    assert {:ok, %{row: row, case: case}} = Planner.execute(action_plan, row)

    assert %Row{case_uuid: case_uuid, status: :resolved} = row

    assert {:ok, %Case{}} = CaseContext.delete_case(case)

    import_2 = import_fixture(tenant_sg, %{type: :ism_2021_06_11_test})

    row_2 =
      row_fixture(import_2, %{
        data: %{
          "Fall ID" => "2182953",
          "Patient Nachname" => "Licht",
          "Patient Vorname" => "Laura",
          "Patient ID" => "1673735",
          "Patient Strasse" => "Teststrasse 42",
          "Testdatum" => "2021-03-24"
        },
        identifiers: %{"Fall ID" => "2182953"}
      })

    assert {false,
            [
              {:uncertain, _choose_tenant},
              {:input_needed, %{case: nil}}
            ]} = Planner.generate_action_plan_suggestion(row_2)
  end
end
