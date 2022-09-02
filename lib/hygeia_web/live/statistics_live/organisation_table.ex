defmodule HygeiaWeb.StatisticsLive.OrganisationTable do
  @moduledoc false

  use HygeiaWeb, :surface_component

  prop count, :number, default: nil
  prop active_cases_per_day_and_organisation, :list, required: true

  @impl Surface.Component
  def render(assigns) do
    assigns
    |> assign(
      sum_count: Enum.reduce(assigns.active_cases_per_day_and_organisation, 0, &(&1.count + &2))
    )
    |> render_sface()
  end
end
