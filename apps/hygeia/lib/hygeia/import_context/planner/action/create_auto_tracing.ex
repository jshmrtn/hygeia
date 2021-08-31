defmodule Hygeia.ImportContext.Planner.Action.CreateAutoTracing do
  @moduledoc """
  Create Auto Tracing
  """

  @type t :: %__MODULE__{
          action: :create | :skip
        }

  defstruct [:action, :create]

  defimpl Hygeia.ImportContext.Planner.Action do
    alias Hygeia.ImportContext.Planner.Action.CreateAutoTracing

    @impl Hygeia.ImportContext.Planner.Action
    def execute(%CreateAutoTracing{action: :skip}, _preceding_results, _row), do: {:ok, %{}}

    def execute(
          %CreateAutoTracing{action: :create},
          _preceding_results,
          _row
        ),
        do:
          {:ok,
           %{
             create_auto_tracing: true
           }}
  end
end
