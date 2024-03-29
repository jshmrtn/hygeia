defmodule HygeiaWeb.VersionLive.Table do
  @moduledoc false

  use HygeiaWeb, :surface_live_component

  import HygeiaWeb.Helpers.Versioning

  alias Hygeia.Repo
  alias Hygeia.VersionContext.Version
  alias Hygeia.VersionContext.Version.Event
  alias Surface.Components.LiveRedirect

  prop versions, :list, required: true
  prop now, :map, required: true
  prop auth, :map, from_context: {HygeiaWeb, :auth}
  prop timezone, :string, from_context: {HygeiaWeb, :timezone}

  @impl Phoenix.LiveComponent
  def preload(assigns_list),
    do: preload_assigns_many(assigns_list, :versions, &Repo.preload(&1, :user))
end
