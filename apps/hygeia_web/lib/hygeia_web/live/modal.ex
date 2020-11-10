defmodule HygeiaWeb.Modal do
  @moduledoc false

  use HygeiaWeb, :surface_live_component

  alias Surface.Components.LivePatch

  prop title, :string, default: ""
  prop close, :event, default: nil
end
