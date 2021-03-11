defmodule HygeiaWeb.StatisticsLive.CountryTable do
  @moduledoc false

  use HygeiaWeb, :surface_component

  prop count, :number, default: nil
  prop transmission_country_cases_per_day, :list, required: true
end
