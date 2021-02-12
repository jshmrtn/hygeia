defmodule HygeiaWeb.TenantLive.Export do
  @moduledoc false

  use HygeiaWeb, :surface_view

  alias Hygeia.TenantContext
  alias Hygeia.TenantContext.Tenant
  alias Surface.Components.Link

  data tenant, :map, default: nil
  data format, :atom, default: nil

  @impl Phoenix.LiveView
  def handle_params(%{"id" => id}, _uri, socket) do
    tenant = TenantContext.get_tenant!(id)

    socket =
      if authorized?(tenant, :export_data, get_auth(socket)) do
        Phoenix.PubSub.subscribe(Hygeia.PubSub, "tenants:#{id}")

        assign(socket, tenant: tenant)
      else
        socket
        |> push_redirect(to: Routes.home_index_path(socket, :index))
        |> put_flash(:error, gettext("You are not authorized to do this action."))
      end

    {:noreply, socket}
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
end
