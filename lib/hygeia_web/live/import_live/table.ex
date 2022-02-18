defmodule HygeiaWeb.ImportLive.Table do
  @moduledoc false

  use HygeiaWeb, :surface_live_component

  alias Hygeia.ImportContext.Import
  alias Hygeia.ImportContext.Import.Type

  alias Surface.Components.Context
  alias Surface.Components.Link
  alias Surface.Components.LiveRedirect

  prop imports, :list, default: []
  prop show_controls, :boolean, default: true

  prop delete_event, :event
end
