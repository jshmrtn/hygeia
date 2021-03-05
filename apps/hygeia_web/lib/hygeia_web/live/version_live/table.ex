defmodule HygeiaWeb.VersionLive.Table do
  @moduledoc false

  use HygeiaWeb, :surface_live_component

  alias Hygeia.Repo
  alias Hygeia.VersionContext.Version
  alias Hygeia.VersionContext.Version.Event
  alias Surface.Components.LiveRedirect

  prop versions, :list, required: true
  prop now, :map, required: true

  @impl Phoenix.LiveComponent
  def preload(assigns_list),
    do: preload_assigns_many(assigns_list, :versions, &Repo.preload(&1, :user))
end
