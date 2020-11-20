defmodule HygeiaWeb.CaseLive.PersonCreateTable do
  @moduledoc false

  use HygeiaWeb, :surface_live_component

  alias Hygeia.CaseContext
  alias Hygeia.CaseContext.Case.ContactMethod
  alias Hygeia.TenantContext
  alias Surface.Components.Form.DateInput
  alias Surface.Components.Form.ErrorTag
  alias Surface.Components.Form.Field
  alias Surface.Components.Form.HiddenInput
  alias Surface.Components.Form.Input.InputContext
  alias Surface.Components.Form.Inputs
  alias Surface.Components.Form.Select
  alias Surface.Components.Form.TextInput

  prop tenants, :list, required: true
  prop supervisor_users, :list, required: true
  prop tracer_users, :list, required: true
  prop default_country, :string, default: nil

  slot additional_header, required: false
  slot additional_row, required: false, props: [:disabled]

  @impl Phoenix.LiveComponent
  def mount(socket) do
    {:ok, assign(socket, suspected_duplicate_changeset_uuid: nil)}
  end

  @impl Phoenix.LiveComponent
  def handle_event("check_duplicate", %{"changeset-uuid" => uuid} = _params, socket) do
    {:noreply, assign(socket, suspected_duplicate_changeset_uuid: uuid)}
  end

  @impl Phoenix.LiveComponent
  def handle_event("remove_person", %{"changeset-uuid" => uuid}, socket) do
    send(self(), {:remove_person, uuid})

    {:noreply, socket}
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

  defp get_person(uuid), do: CaseContext.get_person!(uuid)

  defp get_person_name(person) do
    "#{person.first_name} #{person.last_name}"
  end

  defp get_contact_method(person, type) do
    person.contact_methods
    |> Enum.find(&match?(^type, &1.type))
    |> case do
      nil -> nil
      %ContactMethod{value: value, type: ^type} -> value
    end
  end

  defp get_tenant(tenants, uuid),
    do: Enum.find(tenants, &match?(%TenantContext.Tenant{uuid: ^uuid}, &1))
end
