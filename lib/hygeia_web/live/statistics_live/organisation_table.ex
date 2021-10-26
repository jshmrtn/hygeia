defmodule HygeiaWeb.StatisticsLive.OrganisationTable do
  @moduledoc false

  use HygeiaWeb, :surface_component

  prop count, :number, default: nil
  prop active_cases_per_day_and_organisation, :list, required: true
end
