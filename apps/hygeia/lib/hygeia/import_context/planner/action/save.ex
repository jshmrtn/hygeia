defmodule Hygeia.ImportContext.Planner.Action.Save do
  @moduledoc """
  Save Execution Plan to Database
  """

  @type t :: %__MODULE__{}

  defstruct []

  defimpl Hygeia.ImportContext.Planner.Action do
    alias Hygeia.AutoTracingContext
    alias Hygeia.AutoTracingContext.AutoTracingCommunication
    alias Hygeia.CaseContext
    alias Hygeia.CommunicationContext
    alias Hygeia.ImportContext
    alias Hygeia.ImportContext.Planner.Action.Save
    alias Hygeia.Repo

    @impl Hygeia.ImportContext.Planner.Action
    def execute(
          %Save{},
          %{
            case: nil,
            person: nil,
            case_changeset: case_changeset,
            person_changeset: person_changeset,
            note_changeset: note_changeset
          } = params,
          row
        ) do
      person_changeset = CaseContext.change_person(person_changeset)

      with {:ok, person} <- CaseContext.create_person(person_changeset),
           case_changeset = CaseContext.change_case(case_changeset, %{person_uuid: person.uuid}),
           {:ok, case} <- CaseContext.create_case(case_changeset),
           {:ok, _note} <- create_note_as_needed(case, note_changeset),
           {:ok, _auto_tracing} <-
             create_auto_tracing_as_needed(case, params[:create_auto_tracing]),
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
          } = params,
          row
        ) do
      person_changeset = CaseContext.change_person(person_changeset)

      with {:ok, person} <- CaseContext.update_person(person_changeset),
           case_changeset = CaseContext.change_case(case_changeset, %{person_uuid: person.uuid}),
           {:ok, case} <- CaseContext.create_case(case_changeset),
           {:ok, _note} <- create_note_as_needed(case, note_changeset),
           {:ok, _auto_tracing} <-
             create_auto_tracing_as_needed(case, params[:create_auto_tracing]),
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
          } = params,
          row
        ) do
      person_changeset = CaseContext.change_person(person_changeset)

      with {:ok, person} <- CaseContext.update_person(person_changeset),
           case_changeset = CaseContext.change_case(case_changeset),
           {:ok, case} <- CaseContext.update_case(case_changeset),
           {:ok, _note} <- create_note_as_needed(case, note_changeset),
           {:ok, _auto_tracing} <-
             create_auto_tracing_as_needed(case, params[:create_auto_tracing]),
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

    defp create_auto_tracing_as_needed(case, create_auto_tracing)

    defp create_auto_tracing_as_needed(case, true) do
      case = Repo.preload(case, person: [], tenant: [])

      {:ok, auto_tracing} = AutoTracingContext.create_auto_tracing(case)

      case
      |> CommunicationContext.create_outgoing_sms(AutoTracingCommunication.auto_tracing_sms(case))
      |> case do
        {:ok, _sms} -> :ok
        {:error, :no_mobile_number} -> :ok
        {:error, :sms_config_missing} -> :ok
      end

      case
      |> CommunicationContext.create_outgoing_email(
        AutoTracingCommunication.auto_tracing_email_subject(),
        AutoTracingCommunication.auto_tracing_email_body(case, :email)
      )
      |> case do
        {:ok, _email} -> :ok
        {:error, :no_email} -> :ok
        {:error, :no_outgoing_mail_configuration} -> :ok
      end

      {:ok, auto_tracing}
    end

    defp create_auto_tracing_as_needed(_case, _nil_or_false), do: {:ok, nil}
  end
end
