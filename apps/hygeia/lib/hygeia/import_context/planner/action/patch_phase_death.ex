defmodule Hygeia.ImportContext.Planner.Action.PatchPhaseDeath do
  @moduledoc """
  Patch Index Phase to End Reason "death"
  """

  @type t :: %__MODULE__{}

  defstruct []

  defimpl Hygeia.ImportContext.Planner.Action do
    alias Ecto.Changeset
    alias Hygeia.CaseContext.Case.Phase
    alias Hygeia.ImportContext.Planner.Action.PatchPhaseDeath

    @impl Hygeia.ImportContext.Planner.Action
    def execute(%PatchPhaseDeath{}, %{case_changeset: case_changeset}, _row) do
      fallback_phases =
        case_changeset
        |> Changeset.fetch_field!(:phases)
        |> Enum.map(&Changeset.change/1)

      phases =
        case_changeset
        |> Changeset.get_change(:phases, fallback_phases)
        |> Enum.map(fn phase_changeset ->
          case Changeset.fetch_field!(phase_changeset, :details) do
            %Phase.Index{} ->
              Phase.changeset(phase_changeset, %{details: %{__type__: :index, end_reason: :death}})

            %Phase.PossibleIndex{} ->
              phase_changeset
          end
        end)

      {:ok, %{case_changeset: Changeset.put_embed(case_changeset, :phases, phases)}}
    end
  end
end
