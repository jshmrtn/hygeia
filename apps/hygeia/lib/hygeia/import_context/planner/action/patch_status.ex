defmodule Hygeia.ImportContext.Planner.Action.PatchStatus do
  @moduledoc """
  Patch Case Status
  """

  @type t :: %__MODULE__{
          action: :change | :skip,
          status: Hygeia.CaseContext.Case.Status.t() | nil
        }

  defstruct [:action, :status]

  defimpl Hygeia.ImportContext.Planner.Action do
    alias Ecto.Changeset
    alias Hygeia.ImportContext.Planner.Action.PatchStatus

    @impl Hygeia.ImportContext.Planner.Action
    def execute(%PatchStatus{action: :skip}, _preceding_results, _row), do: {:ok, %{}}

    def execute(
          %PatchStatus{action: :change, status: status},
          %{case_changeset: case_changeset},
          _row
        ) do
      {:ok, %{case_changeset: Changeset.change(case_changeset, %{status: status})}}
    end
  end
end
