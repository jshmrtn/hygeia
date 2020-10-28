defmodule HygeiaWeb.CaseLive.Navigation do
  @moduledoc false

  use HygeiaWeb, :surface_live_component

  alias Surface.Components.LivePatch

  prop case, :map, required: true
  prop active_view, :atom, required: true
end
