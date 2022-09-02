defmodule HygeiaWeb.StatisticsLive.InfectionPlaceTable do
  @moduledoc false

  use HygeiaWeb, :surface_component

  prop count, :number, default: nil
  prop active_infection_place_cases_per_day, :list, required: true

  @impl Surface.Component
  def render(assigns) do
    assigns
    |> assign(
      sum_count: Enum.reduce(assigns.active_infection_place_cases_per_day, 0, &(&1.count + &2))
    )
    |> render_sface()
  end
end
