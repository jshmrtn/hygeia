defmodule HygeiaWeb.OrganisationLive.Index do
  @moduledoc false

  use HygeiaWeb, :live_view

  alias Hygeia.Helpers.Versioning
  alias Hygeia.OrganisationContext
  alias Hygeia.OrganisationContext.Organisation

  @impl Phoenix.LiveView
  def mount(_params, session, socket) do
    Phoenix.PubSub.subscribe(Hygeia.PubSub, "organisations")

    unless is_nil(session["cldr_locale"]) do
      HygeiaWeb.Cldr.put_locale(session["cldr_locale"])
    end

    # TODO: Replace with correct Origin / Originator
    Versioning.put_origin(:web)
    Versioning.put_originator(:noone)

    {:ok, assign(socket, :organisations, list_organisations())}
  end

  @impl Phoenix.LiveView
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, gettext("Edit Organisation"))
    |> assign(:organisation, OrganisationContext.get_organisation!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, gettext("New Organisation"))
    |> assign(:organisation, %Organisation{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, gettext("Listing Organisations"))
    |> assign(:organisation, nil)
  end

  @impl Phoenix.LiveView
  def handle_event("delete", %{"id" => id}, socket) do
    organisation = OrganisationContext.get_organisation!(id)
    {:ok, _} = OrganisationContext.delete_organisation(organisation)

    {:noreply, assign(socket, :organisations, list_organisations())}
  end

  @impl Phoenix.LiveView
  def handle_info({_type, %Organisation{}, _version}, socket) do
    {:noreply, assign(socket, :organisations, list_organisations())}
  end

  defp list_organisations, do: OrganisationContext.list_organisations()
end
