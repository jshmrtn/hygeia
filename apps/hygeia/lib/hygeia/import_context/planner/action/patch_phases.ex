defmodule Hygeia.ImportContext.Planner.Action.PatchPhases do
  @moduledoc """
  Patch / Append Phases
  """

  @type t :: %__MODULE__{action: :append | :skip, phase_type: :index}

  defstruct [:action, :phase_type]

  defimpl Hygeia.ImportContext.Planner.Action do
    alias Ecto.Changeset
    alias Hygeia.CaseContext.Case.Phase
    alias Hygeia.ImportContext.Planner.Action.PatchPhases

    @impl Hygeia.ImportContext.Planner.Action
    def execute(%PatchPhases{action: :skip}, _preceding_results, _row), do: {:ok, %{}}

    def execute(
          %PatchPhases{action: :append, phase_type: phase_type},
          %{case_changeset: case_changeset},
          _row
        ) do
      fallback_phases =
        case_changeset
        |> Changeset.fetch_field!(:phases)
        |> Enum.map(&Changeset.change/1)

      phases =
        Changeset.get_change(case_changeset, :phases, fallback_phases) ++
          [Phase.changeset(%Phase{}, %{details: %{__type__: phase_type}})]

      {:ok, %{case_changeset: Changeset.put_embed(case_changeset, :phases, phases)}}
    end
  end
end
