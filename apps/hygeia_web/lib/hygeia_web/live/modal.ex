defmodule HygeiaWeb.Modal do
  @moduledoc false

  use HygeiaWeb, :surface_live_component

  prop title, :string, default: ""
  prop close, :event, default: nil

  slot default, required: true
end
