defmodule HygeiaWeb.CaseLive.RelatedOrganisations do
  @moduledoc false

  use HygeiaWeb, :surface_live_component

  alias Surface.Components.Form.ErrorTag
  alias Surface.Components.Form.Field
  alias Surface.Components.Form.Input.InputContext
  alias Surface.Components.Form.Inputs

  prop disabled, :boolean, default: false

  @impl Phoenix.LiveComponent
  def handle_event("change", %{"from-uuid" => from_uuid} = _params, socket) do
    send(self(), {:remove_related_organisation, from_uuid})
    {:noreply, socket}
  end

  def handle_event("change", %{"uuid" => new_uuid} = _params, socket) do
    send(self(), {:add_related_organisation, new_uuid})
    {:noreply, socket}
  end
end
