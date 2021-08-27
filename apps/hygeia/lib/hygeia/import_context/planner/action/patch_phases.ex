defmodule Hygeia.ImportContext.Planner.Action.PatchPhases do
  @moduledoc """
  Patch / Append Phases
  """

  @type t :: %__MODULE__{
          action: :append | :skip,
          phase_type: :index,
          quarantine_order: boolean() | nil
        }

  defstruct [:action, :phase_type, :quarantine_order]

  defimpl Hygeia.ImportContext.Planner.Action do
    alias Ecto.Changeset
    alias Hygeia.CaseContext.Case.Phase
    alias Hygeia.ImportContext.Planner.Action.PatchPhases

    @impl Hygeia.ImportContext.Planner.Action
    def execute(%PatchPhases{action: :skip}, _preceding_results, _row), do: {:ok, %{}}

    def execute(
          %PatchPhases{
            action: :append,
            phase_type: phase_type,
            quarantine_order: quarantine_order
          },
          %{case_changeset: case_changeset},
          _row
        ) do
      fallback_phases =
        case_changeset
        |> Changeset.fetch_field!(:phases)
        |> Enum.map(&Changeset.change/1)

      phases =
        case_changeset
        |> Changeset.get_change(:phases, fallback_phases)
        |> List.update_at(-1, fn phase_changeset ->
          Phase.changeset(phase_changeset, %{details: %{end_reason: :converted_to_index}})
        end)

      phases =
        phases ++
          [
            Phase.changeset(%Phase{}, %{
              details: %{__type__: phase_type},
              quarantine_order: quarantine_order
            })
          ]

      {:ok, %{case_changeset: Changeset.put_embed(case_changeset, :phases, phases)}}
    end
  end
end
