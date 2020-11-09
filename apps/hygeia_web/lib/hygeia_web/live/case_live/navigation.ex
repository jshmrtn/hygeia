defmodule HygeiaWeb.CaseLive.Navigation do
  @moduledoc false

  use HygeiaWeb, :surface_live_component

  alias Hygeia.CaseContext.Phase
  alias HygeiaWeb.UriActiveContext
  alias Surface.Components.Link
  alias Surface.Components.LiveRedirect

  prop case, :map, required: true
end
