defmodule HygeiaWeb.TenantLive.Show do
  @moduledoc false

  use HygeiaWeb, :live_view

  alias Hygeia.TenantContext
  alias Hygeia.TenantContext.Tenant

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def handle_params(%{"id" => id}, _uri, socket) do
    Phoenix.PubSub.subscribe(Hygeia.PubSub, "tenants:#{id}")

    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:tenant, TenantContext.get_tenant!(id))}
  end

  @impl Phoenix.LiveView
  def handle_info({:updated, %Tenant{} = tenant}, socket) do
    {:noreply, assign(socket, :tenant, tenant)}
  end

  @impl Phoenix.LiveView
  def handle_info({:deleted, %Tenant{}}, socket) do
    {:noreply, redirect(socket, to: Routes.tenant_index_path(socket, :index))}
  end

  defp page_title(:show), do: gettext("Show Tenant")
  defp page_title(:edit), do: gettext("Edit Tenant")
end
