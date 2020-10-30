defmodule HygeiaWeb.CaseLive.PersonCreateTable do
  @moduledoc false

  use HygeiaWeb, :surface_live_component

  alias Hygeia.CaseContext
  alias HygeiaWeb.FormError
  alias Surface.Components.Form.Field
  alias Surface.Components.Form.HiddenInput
  alias Surface.Components.Form.Input.InputContext
  alias Surface.Components.Form.Inputs
  alias Surface.Components.Form.Select
  alias Surface.Components.Form.TextInput

  prop tenants, :list, required: true
  prop users, :list, required: true

  @impl Phoenix.LiveComponent
  def mount(socket) do
    {:ok, assign(socket, suspected_duplicate_changeset_uuid: nil)}
  end

  @impl Phoenix.LiveComponent
  def handle_event("check_duplicate", %{"changeset-uuid" => uuid} = _params, socket) do
    {:noreply, assign(socket, suspected_duplicate_changeset_uuid: uuid)}
  end

  def handle_event(
        "select_accepted_duplicate",
        %{"person-uuid" => duplicate_uuid},
        %{assigns: %{suspected_duplicate_changeset_uuid: uuid}} = socket
      ) do
    person = CaseContext.get_person!(duplicate_uuid)

    send(self(), {:accept_duplicate, uuid, person})

    {:noreply, assign(socket, suspected_duplicate_changeset_uuid: nil)}
  end

  def handle_event(
        "decline_duplicate",
        _params,
        %{assigns: %{suspected_duplicate_changeset_uuid: uuid}} = socket
      ) do
    send(self(), {:declined_duplicate, uuid})

    {:noreply, assign(socket, suspected_duplicate_changeset_uuid: nil)}
  end

  defp get_person_name(uuid) do
    CaseContext.get_person!(uuid).first_name
  end
end
