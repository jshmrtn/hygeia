defmodule Hygeia.ImportContext.Planner do
  @moduledoc """
  Action Plan Generator for Import Rows
  """

  alias Hygeia.ImportContext
  alias Hygeia.ImportContext.Import
  alias Hygeia.ImportContext.Import.Type
  alias Hygeia.ImportContext.Planner.Action
  alias Hygeia.ImportContext.Row
  alias Hygeia.Repo

  @type certainty :: :input_needed | :uncertain | :certain

  @type action_plan_suggestion :: [{certainty, Action.t()}]

  @type action_execute_meta :: map
  @type execution_acc ::
          {:ok, results :: action_execute_meta}
          | {:error, {Action.t(), reason :: term}}

  @spec generate_action_plan_suggestion(row :: Row.t(), given_steps :: [Action.t()]) ::
          {complete :: boolean, action_plan_suggestion}
  def generate_action_plan_suggestion(row, given_steps \\ [])

  def generate_action_plan_suggestion(
        %Row{import: %Ecto.Association.NotLoaded{}} = row,
        given_steps
      ),
      do: row |> Repo.preload(:import) |> generate_action_plan_suggestion(given_steps)

  def generate_action_plan_suggestion(%Row{import: %Import{type: type}} = row, given_steps) do
    predecessor = ImportContext.get_row_predecessor(row)

    generator = Type.action_plan_generator(type)

    {row, params} =
      generator.before_action_plan(row, %{
        predecessor: predecessor,
        changes: Row.get_changes(row, predecessor),
        data: row.data
      })

    generator_functions = generator.action_plan_steps()

    {complete, new_steps} =
      generator_functions
      |> Enum.slice(length(given_steps), length(generator_functions))
      |> Enum.reduce_while(
        {true, given_steps |> Enum.reverse() |> Enum.map(&{:certain, &1})},
        fn step_generator, {_complete, acc} ->
          row
          |> step_generator.(params, acc)
          |> case do
            nil -> {:cont, {true, [acc]}}
            {:certain, _action} = suggestion -> {:cont, {true, [suggestion | acc]}}
            {:uncertain, _action} = suggestion -> {:cont, {true, [suggestion | acc]}}
            {:input_needed, _action} = suggestion -> {:halt, {false, [suggestion | acc]}}
          end
        end
      )

    {complete, Enum.reverse(new_steps)}
  end

  @spec execute(action_plan :: [Action.t()], row :: Row.t()) :: execution_acc
  def execute(action_plan, row) do
    Repo.transaction(fn ->
      action_plan
      |> Enum.reduce_while({:ok, %{}}, &execute_action(&1, &2, row))
      |> case do
        {:ok, result} -> result
        {:error, reason} -> Repo.rollback(reason)
      end
    end)
  end

  @spec execute_action(action :: Action.t(), acc :: execution_acc, row :: Row.t()) ::
          {:cont, execution_acc} | {:halt, execution_acc()}
  defp execute_action(action, {:ok, preceding_results}, row) do
    action
    |> Action.execute(preceding_results, row)
    |> case do
      {:ok, action_execute_meta} ->
        {:cont, {:ok, Map.merge(preceding_results, action_execute_meta)}}

      {:error, reason} ->
        {:halt, {:error, {action, reason, preceding_results}}}
    end
  end

  @spec limit_certainty(certainty :: certainty, max_certainty :: certainty) :: certainty
  def limit_certainty(certainty, max_certainty)
  def limit_certainty(certainty, :certain), do: certainty
  def limit_certainty(:input_needed, :uncertain), do: :input_needed
  def limit_certainty(_certainty, :uncertain), do: :uncertain
  def limit_certainty(:_certainty, :input_needed), do: :input_needed
end
