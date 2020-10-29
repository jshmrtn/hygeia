defmodule HygeiaWeb.TenantLive.Show do
  @moduledoc false

  use HygeiaWeb, :live_view

  alias Hygeia.TenantContext
  alias Hygeia.TenantContext.Tenant

  @impl Phoenix.LiveView
  def handle_params(%{"id" => id}, _uri, socket) do
    Phoenix.PubSub.subscribe(Hygeia.PubSub, "tenants:#{id}")

    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:tenant, TenantContext.get_tenant!(id))}
  end

  @impl Phoenix.LiveView
  def handle_info({:updated, %Tenant{} = tenant, _version}, socket) do
    {:noreply, assign(socket, :tenant, tenant)}
  end

  @impl Phoenix.LiveView
  def handle_info({:deleted, %Tenant{}, _version}, socket) do
    {:noreply, redirect(socket, to: Routes.tenant_index_path(socket, :index))}
  end

  def handle_info(_other, socket), do: {:noreply, socket}

  defp page_title(:show), do: gettext("Show Tenant")
  defp page_title(:edit), do: gettext("Edit Tenant")
end
