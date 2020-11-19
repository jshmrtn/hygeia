defmodule HygeiaWeb.CaseLive.Hospitalizations do
  @moduledoc false

  use HygeiaWeb, :surface_live_component

  alias Surface.Components.Form.DateInput
  alias Surface.Components.Form.ErrorTag
  alias Surface.Components.Form.Field
  alias Surface.Components.Form.HiddenInput
  alias Surface.Components.Form.Input.InputContext
  alias Surface.Components.Form.Inputs
  alias Surface.Components.Form.Label

  prop source, :map, required: true
  prop organisations, :list, required: true
  prop add_hospitalization, :event, required: true
  prop remove_hospitalization, :event, required: true
  prop disabled, :boolean, default: false

  @impl Phoenix.LiveComponent
  def handle_event("change_organisation_" <> changeset_uuid, params, socket) do
    send(self(), {:hospitalisation_change_organisation, changeset_uuid, params["uuid"]})
    {:noreply, socket}
  end
end
