defmodule Hygeia.ImportContext.Planner.Generator do
  @moduledoc false

  alias Hygeia.ImportContext.Planner
  alias Hygeia.ImportContext.Planner.Action
  alias Hygeia.ImportContext.Row

  @type t :: []

  @type params :: %{
          required(:predecessor) => Row.t() | nil,
          required(:changes) => map,
          required(:data) => map,
          optional(atom) => term()
        }

  @callback before_action_plan(row :: Row.t(), params :: params) :: {Row.t(), params}

  @callback action_plan_steps :: [
              (row :: Row.t(), params :: params, preceeding_action_plan :: [Action.t()] ->
                 {Planner.certainty(), Action.t()})
            ]

  @callback id_fields :: [String.t()]
  @callback display_field_grouping :: %{
              (section_name :: String.t()) => MapSet.t(field_name :: String.t())
            }
  @callback list_fields :: [String.t()]

  defmacro __using__(_opts) do
    quote do
      @behaviour unquote(__MODULE__)

      @impl unquote(__MODULE__)
      def before_action_plan(row, params), do: {row, params}

      defoverridable before_action_plan: 2
    end
  end
end
