defmodule HygeiaWeb.StatisticsLive.Header do
  @moduledoc false

  use HygeiaWeb, :surface_live_component

  alias HygeiaWeb.UriActiveContext
  alias Surface.Components.Context
  alias Surface.Components.LiveRedirect

  prop tenant, :map, required: true
end
