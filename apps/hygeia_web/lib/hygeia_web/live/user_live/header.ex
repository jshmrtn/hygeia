defmodule HygeiaWeb.UserLive.Header do
  @moduledoc false

  use HygeiaWeb, :surface_live_component

  alias HygeiaWeb.UriActiveContext
  alias Surface.Components.LiveRedirect

  prop user, :map, required: true
end
