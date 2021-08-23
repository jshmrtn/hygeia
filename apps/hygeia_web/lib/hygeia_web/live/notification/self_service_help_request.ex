defmodule HygeiaWeb.Notification.SelfServiceHelpRequest do
  @moduledoc false

  use HygeiaWeb, :surface_live_component

  alias Hygeia.Repo
  alias Surface.Components.LiveRedirect

  prop body, :map, required: true

  @impl Phoenix.LiveComponent
  def preload(assign_list),
    do: preload_assigns_one(assign_list, :body, &Repo.preload(&1, case: :person))
end
