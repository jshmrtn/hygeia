# credo:disable-for-this-file Credo.Check.Readability.ModuleNames
# credo:disable-for-this-file Credo.Check.Design.DuplicatedCode
defmodule Hygeia.ImportContext.Planner.Generator.ISM_2021_06_11_TestTest do
  @moduledoc false

  use ExUnit.Case
  use Hygeia.DataCase

  alias Hygeia.ImportContext
  alias Hygeia.ImportContext.Planner

  @moduletag origin: :test
  @moduletag originator: :noone

  setup do
    tenant = tenant_fixture()

    import = import_fixture(tenant, %{type: :ism_2021_06_11_test})

    row =
      row_fixture(import, %{
        data: %{
          "Fall ID" => "2182953",
          "Patient Nachname" => "Muster",
          "Patient Vorname" => "Max",
          "Patient ID" => "1673735",
          "Testdatum" => Date.to_iso8601(Date.add(Date.utc_today(), -1))
        },
        identifiers: %{"Fall ID" => "2182953"}
      })

    person =
      person_fixture(tenant, %{
        last_name: "Muster",
        first_name: "Max",
        external_references: [%{type: :ism_patient, value: "1673735"}]
      })

    {:ok, person: person, row: row, tenant: tenant, import: import}
  end

  test "input_needed when same ism id for possible index case older than 10 days ", %{
    person: person,
    row: row
  } do
    _case = import_case_fixture(person, %{__type__: :possible_index, type: :contact_person}, 15)

    assert {false,
            [
              {:uncertain, _choose_tenant},
              {:input_needed, _select_case}
            ]} = Planner.generate_action_plan_suggestion(row)
  end

  test "input_needed when same ism id for possible index case older than 10 days with previous import ",
       %{
         person: person,
         row: row_1,
         tenant: tenant
       } do
    case = import_case_fixture(person, %{__type__: :possible_index, type: :contact_person}, 15)

    {:ok, _row_1} = ImportContext.update_row(row_1, %{case_uuid: case.uuid, status: :resolved})

    import_2 = import_fixture(tenant, %{type: :ism_2021_06_11_test})

    row_2 =
      row_fixture(import_2, %{
        data: %{
          "Fall ID" => "2182953",
          "Patient Nachname" => "Muster",
          "Patient Vorname" => "Max",
          "Patient ID" => "1673735",
          "Testdatum" => Date.to_iso8601(Date.add(Date.utc_today(), -1)),
          "new" => "key"
        },
        identifiers: %{"Fall ID" => "2182953"}
      })

    assert {false,
            [
              {:uncertain, _choose_tenant},
              {:input_needed, _select_case}
            ]} = Planner.generate_action_plan_suggestion(row_2)
  end

  test "certain when same ism id for possible index case not older than 10 days ", %{
    person: person,
    row: row
  } do
    _case = import_case_fixture(person, %{__type__: :possible_index, type: :contact_person}, 1)

    assert {true,
            [
              {:uncertain, _choose_tenant},
              {:certain, _select_case} | _other_actions
            ]} = Planner.generate_action_plan_suggestion(row)
  end

  test "input_needed when same ism id for index case older than 30 days ", %{
    person: person,
    row: row
  } do
    _case = import_case_fixture(person, %{__type__: :index}, 40)

    assert {false,
            [
              {:uncertain, _choose_tenant},
              {:input_needed, %Planner.Action.SelectCase{suppress_quarantine: false}}
            ]} = Planner.generate_action_plan_suggestion(row)
  end

  test "input_needed when same ism id for index case between 11 and 30 days old ", %{
    person: person,
    row: row
  } do
    _case = import_case_fixture(person, %{__type__: :index}, 20)

    assert {false,
            [
              {:uncertain, _choose_tenant},
              {:input_needed, %Planner.Action.SelectCase{suppress_quarantine: true}}
            ]} = Planner.generate_action_plan_suggestion(row)
  end

  test "uncertain when same ism id for index case not older than 10 days ", %{
    person: person,
    row: row
  } do
    _case = import_case_fixture(person, %{__type__: :index}, 5)

    assert {true,
            [
              {:uncertain, _choose_tenant},
              {:uncertain, %Planner.Action.SelectCase{suppress_quarantine: nil}} | _other_actions
            ]} = Planner.generate_action_plan_suggestion(row)
  end

  test "certain when same ism id for index case not older than 10 days ", %{
    person: person,
    row: row
  } do
    # days_ago = 1 for "Testdatum" between start and end
    _case = import_case_fixture(person, %{__type__: :index}, 1)

    assert {true,
            [
              {:uncertain, _choose_tenant},
              {:certain, %Planner.Action.SelectCase{suppress_quarantine: nil}} | _other_actions
            ]} = Planner.generate_action_plan_suggestion(row)
  end

  defp import_case_fixture(person, details, days_ago) do
    start_end_date = Date.add(Date.utc_today(), -days_ago)
    inserted_at = DateTime.add(DateTime.utc_now(), -days_ago * 86_400)

    case_fixture(
      person,
      user_fixture(%{iam_sub: Ecto.UUID.generate()}),
      user_fixture(%{iam_sub: Ecto.UUID.generate()}),
      %{
        external_references: [
          %{type: :ism_case, value: "2182953"}
        ],
        phases: [
          %{
            details: details,
            start: start_end_date,
            end: start_end_date,
            quarantine_order: true,
            inserted_at: inserted_at
          }
        ],
        tests: [],
        inserted_at: inserted_at,
        clinical: %{}
      }
    )
  end
end
