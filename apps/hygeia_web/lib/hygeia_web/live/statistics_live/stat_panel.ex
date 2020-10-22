defmodule HygeiaWeb.StatisticsLive.StatPanel do
  @moduledoc false

  use HygeiaWeb, :surface_component

  prop(header, :string, required: true)
  prop(value, :number, required: true)
  prop(label, :string, required: true)
end
