defmodule HygeiaWeb.Helpers.FormStep do
  @moduledoc "Describes a step in the multi-step form
              with next step and previous step transitions."
  defstruct [:name, :prev, :next]
end
