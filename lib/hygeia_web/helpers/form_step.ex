defmodule HygeiaWeb.Helpers.FormStep do
  @moduledoc "Describes a step in the multi-step form
              with next step and previous step transitions."

  @type empty :: %__MODULE__{
          name: atom() | nil,
          prev: atom() | nil,
          next: atom() | nil
        }

  @type t :: %__MODULE__{
          name: atom() | nil,
          prev: atom() | nil,
          next: atom() | nil
        }

  defstruct [:name, :prev, :next]

  @spec member?(steps :: list(__MODULE__.t()), current_step_name :: atom()) ::
          boolean()
  def member?(steps, step_name) do
    steps
    |> get_step_names()
    |> Enum.member?(step_name)
  end

  @spec get_previous_step(steps :: list(__MODULE__.t()), current_step_name :: atom()) ::
          atom() | nil
  def get_previous_step(steps, current_step_name) do
    get_step_by_direction(steps, current_step_name, :prev)
  end

  @spec get_next_step(steps :: list(__MODULE__.t()), current_step_name :: atom()) ::
          atom() | nil
  def get_next_step(steps, current_step_name) do
    get_step_by_direction(steps, current_step_name, :next)
  end

  defp get_step_by_direction(steps, current_step_name, direction) when is_atom(direction) do
    case get_step(steps, current_step_name) do
      %{^direction => desired_step_name} -> desired_step_name
      nil -> nil
    end
  end

  defp get_step(_steps, nil), do: nil

  defp get_step(steps, step_name) do
    Enum.find(steps, &match?(^step_name, &1.name))
  end

  defp get_step_names(step_list) when is_list(step_list),
    do: Enum.map(step_list, &Map.get(&1, :name))
end
