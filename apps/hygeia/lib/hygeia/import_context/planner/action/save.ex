defmodule Hygeia.ImportContext.Planner.Action.Save do
  @moduledoc """
  Save Execution Plan to Database
  """

  @type t :: %__MODULE__{}

  defstruct []

  defimpl Hygeia.ImportContext.Planner.Action do
    alias Hygeia.CaseContext
    alias Hygeia.ImportContext
    alias Hygeia.ImportContext.Planner.Action.Save

    @impl Hygeia.ImportContext.Planner.Action
    def execute(
          %Save{},
          %{
            case: nil,
            person: nil,
            case_changeset: case_changeset,
            person_changeset: person_changeset
          },
          row
        ) do
      person_changeset = CaseContext.change_person(person_changeset)

      with {:ok, person} <- CaseContext.create_person(person_changeset),
           case_changeset = CaseContext.change_case(case_changeset, %{person_uuid: person.uuid}),
           {:ok, case} <- CaseContext.create_case(case_changeset),
           {:ok, row} <- ImportContext.update_row(row, %{status: :resolved, case_uuid: case.uuid}) do
        {:ok,
         %{
           case: case,
           person: person,
           case_changeset: case_changeset,
           person_changeset: person_changeset,
           row: row
         }}
      end
    end

    def execute(
          %Save{},
          %{
            case: nil,
            person: _person,
            case_changeset: case_changeset,
            person_changeset: person_changeset
          },
          row
        ) do
      person_changeset = CaseContext.change_person(person_changeset)

      with {:ok, person} <- CaseContext.update_person(person_changeset),
           case_changeset = CaseContext.change_case(case_changeset, %{person_uuid: person.uuid}),
           {:ok, case} <- CaseContext.create_case(case_changeset),
           {:ok, row} <- ImportContext.update_row(row, %{status: :resolved, case_uuid: case.uuid}) do
        {:ok,
         %{
           case: case,
           person: person,
           case_changeset: case_changeset,
           person_changeset: person_changeset,
           row: row
         }}
      end
    end

    def execute(
          %Save{},
          %{
            case: _case,
            person: _person,
            case_changeset: case_changeset,
            person_changeset: person_changeset
          },
          row
        ) do
      person_changeset = CaseContext.change_person(person_changeset)

      with {:ok, person} <- CaseContext.update_person(person_changeset),
           case_changeset = CaseContext.change_case(case_changeset),
           {:ok, case} <- CaseContext.update_case(case_changeset),
           {:ok, row} <- ImportContext.update_row(row, %{status: :resolved, case_uuid: case.uuid}) do
        {:ok,
         %{
           case: case,
           person: person,
           case_changeset: case_changeset,
           person_changeset: person_changeset,
           row: row
         }}
      end
    end
  end
end
