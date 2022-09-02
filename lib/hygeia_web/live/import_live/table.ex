defmodule HygeiaWeb.ImportLive.Table do
  @moduledoc false

  use HygeiaWeb, :surface_live_component

  alias Hygeia.ImportContext.Import
  alias Hygeia.ImportContext.Import.Type
  alias Surface.Components.Link
  alias Surface.Components.LiveRedirect

  prop imports, :list, default: []
  prop show_controls, :boolean, default: true

  prop auth, :map, from_context: {HygeiaWeb, :auth}
  prop timezone, :string, from_context: {HygeiaWeb, :timezone}

  prop delete_event, :event
end
