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
            person_changeset: person_changeset,
            note_changeset: note_changeset
          },
          row
        ) do
      person_changeset = CaseContext.change_person(person_changeset)

      with {:ok, person} <- CaseContext.create_person(person_changeset),
           case_changeset = CaseContext.change_case(case_changeset, %{person_uuid: person.uuid}),
           {:ok, case} <- CaseContext.create_case(case_changeset),
           {:ok, _note} <- create_note_as_needed(case, note_changeset),
           {:ok, row} <- ImportContext.update_row(row, %{status: :resolved, case_uuid: case.uuid}) do
        {:ok,
         %{
           case: case,
           person: person,
           case_changeset: case_changeset,
           person_changeset: person_changeset,
           note_changeset: note_changeset,
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
            person_changeset: person_changeset,
            note_changeset: note_changeset
          },
          row
        ) do
      person_changeset = CaseContext.change_person(person_changeset)

      with {:ok, person} <- CaseContext.update_person(person_changeset),
           case_changeset = CaseContext.change_case(case_changeset, %{person_uuid: person.uuid}),
           {:ok, case} <- CaseContext.create_case(case_changeset),
           {:ok, _note} <- create_note_as_needed(case, note_changeset),
           {:ok, row} <- ImportContext.update_row(row, %{status: :resolved, case_uuid: case.uuid}) do
        {:ok,
         %{
           case: case,
           person: person,
           case_changeset: case_changeset,
           person_changeset: person_changeset,
           note_changeset: note_changeset,
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
            person_changeset: person_changeset,
            note_changeset: note_changeset
          },
          row
        ) do
      person_changeset = CaseContext.change_person(person_changeset)

      with {:ok, person} <- CaseContext.update_person(person_changeset),
           case_changeset = CaseContext.change_case(case_changeset),
           {:ok, case} <- CaseContext.update_case(case_changeset),
           {:ok, _note} <- create_note_as_needed(case, note_changeset),
           {:ok, row} <- ImportContext.update_row(row, %{status: :resolved, case_uuid: case.uuid}) do
        {:ok,
         %{
           case: case,
           person: person,
           case_changeset: case_changeset,
           person_changeset: person_changeset,
           note_changeset: note_changeset,
           row: row
         }}
      end
    end

    defp create_note_as_needed(case, changeset)
    defp create_note_as_needed(_case, nil), do: {:ok, nil}

    defp create_note_as_needed(case, changeset),
      do: CaseContext.create_note(case, changeset.changes)
  end
end
