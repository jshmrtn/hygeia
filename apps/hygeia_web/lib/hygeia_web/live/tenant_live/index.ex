defmodule HygeiaWeb.TenantLive.Index do
  @moduledoc false

  use HygeiaWeb, :live_view

  alias Hygeia.TenantContext
  alias Hygeia.TenantContext.Tenant

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    Phoenix.PubSub.subscribe(Hygeia.PubSub, "tenants")

    {:ok, assign(socket, :tenants, list_tenants())}
  end

  @impl Phoenix.LiveView
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, gettext("Edit Tenant"))
    |> assign(:tenant, TenantContext.get_tenant!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Tenant")
    |> assign(:tenant, %Tenant{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, gettext("Listing Tenants"))
    |> assign(:tenant, nil)
  end

  @impl Phoenix.LiveView
  def handle_event("delete", %{"id" => id}, socket) do
    tenant = TenantContext.get_tenant!(id)
    {:ok, _} = TenantContext.delete_tenant(tenant)

    {:noreply, assign(socket, :tenants, list_tenants())}
  end

  @impl Phoenix.LiveView
  def handle_info({_type, %Tenant{}}, socket) do
    {:noreply, assign(socket, :tenants, list_tenants())}
  end

  defp list_tenants do
    TenantContext.list_tenants()
  end
end
