defmodule HygeiaWeb.Helpers.FormStep do
  @moduledoc "Describes a step in the multi-step form
              with next step and previous step transitions."
  defstruct [:name, :prev, :next]

  def get_step_names(step_list) when is_list(step_list),
    do: Enum.map(step_list, &Map.get(&1, :name))
end
