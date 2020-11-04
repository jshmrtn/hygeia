defmodule HygeiaWeb.CaseLive.Navigation do
  @moduledoc false

  use HygeiaWeb, :surface_live_component

  alias HygeiaWeb.UriActiveContext
  alias Surface.Components.LiveRedirect

  prop case, :map, required: true
end
