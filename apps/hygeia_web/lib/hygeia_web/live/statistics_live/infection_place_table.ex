defmodule HygeiaWeb.StatisticsLive.InfectionPlaceTable do
  @moduledoc false

  use HygeiaWeb, :surface_component

  prop count, :number, default: nil
  prop active_infection_place_cases_per_day, :list, required: true
end
