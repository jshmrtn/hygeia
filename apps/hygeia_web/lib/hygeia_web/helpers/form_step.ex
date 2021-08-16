defmodule HygeiaWeb.Helpers.FormStep do
  @moduledoc "Describes a step in the multi-step form
              with next step and previous step transitions."
  defstruct [:name, :prev, :next]

  def member?(step_list, step_name) do
    step_list
    |> get_step_names()
    |> Enum.member?(step_name)
  end

  def get_previous_step(steps, current_step_name) do
    get_step_by_direction(steps, current_step_name, :prev)
  end

  def get_next_step(steps, current_step_name) do
    get_step_by_direction(steps, current_step_name, :next)
  end

  defp get_step_by_direction(steps, current_step_name, direction) when is_atom(direction) do
    steps
    |> get_step(current_step_name)
    |> case do
      nil -> nil
      step ->
        step
        |> Map.get(direction)
        |> case do
          nil -> nil
          desired_step -> desired_step
        end
    end
  end

  defp get_step(_steps, nil), do: nil

  defp get_step(steps, step_name) do
    steps
    |> Enum.find(&(&1.name == step_name))
  end

  def reachable?(steps, source_step, target_step_name)
  def reachable?(_steps, nil, _), do: false
  def reachable?(_steps, _, nil), do: false

  def reachable?(_steps, source_step_name, target_step_name)
    when source_step_name == target_step_name,
      do: true

  def reachable?(steps, source_step_name, target_step_name) do
    reachable?(steps, get_next_step(steps, source_step_name), target_step_name)
  end

  defp get_step_names(step_list) when is_list(step_list),
    do: Enum.map(step_list, &Map.get(&1, :name))
end
