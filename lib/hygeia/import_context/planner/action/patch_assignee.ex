defmodule Hygeia.ImportContext.Planner.Action.PatchAssignee do
  @moduledoc """
  Patch Assignee
  """

  @type t :: %__MODULE__{
          action: :change | :skip,
          tracer_uuid: Ecto.UUID.t() | nil,
          supervisor_uuid: Ecto.UUID.t() | nil
        }

  defstruct [:action, :tracer_uuid, :supervisor_uuid]

  defimpl Hygeia.ImportContext.Planner.Action do
    alias Ecto.Changeset
    alias Hygeia.ImportContext.Planner.Action.PatchAssignee

    @impl Hygeia.ImportContext.Planner.Action
    def execute(%PatchAssignee{action: :skip}, _preceding_results, _row), do: {:ok, %{}}

    def execute(
          %PatchAssignee{
            action: :change,
            supervisor_uuid: supervisor_uuid,
            tracer_uuid: tracer_uuid
          },
          %{case_changeset: case_changeset},
          _row
        ) do
      {:ok,
       %{
         case_changeset:
           Changeset.change(case_changeset, %{
             tracer_uuid: tracer_uuid,
             supervisor_uuid: supervisor_uuid
           })
       }}
    end
  end
end
