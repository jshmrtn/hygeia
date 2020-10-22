defmodule HygeiaWeb.OrganisationLive.Show do
  @moduledoc false

  use HygeiaWeb, :live_view

  alias Hygeia.OrganisationContext
  alias Hygeia.OrganisationContext.Organisation

  @impl Phoenix.LiveView
  def handle_params(%{"id" => id} = params, _uri, socket) do
    Phoenix.PubSub.subscribe(Hygeia.PubSub, "organisations:#{id}")

    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:params, params)
     |> assign(:organisation, OrganisationContext.get_organisation!(id))}
  end

  @impl Phoenix.LiveView
  def handle_info({:updated, %Organisation{} = organisation, _version}, socket) do
    {:noreply, assign(socket, :organisation, organisation)}
  end

  @impl Phoenix.LiveView
  def handle_info({:deleted, %Organisation{}, _version}, socket) do
    {:noreply, redirect(socket, to: Routes.organisation_index_path(socket, :index))}
  end

  defp page_title(:show), do: gettext("Show Organisation")
  defp page_title(:edit), do: gettext("Edit Organisation")
  defp page_title(:position_new), do: gettext("Create Position")
  defp page_title(:position_edit), do: gettext("Edit Position")
end
