defmodule HygeiaWeb.TenantLive.Index do
  @moduledoc false

  use HygeiaWeb, :surface_view

  alias Hygeia.TenantContext
  alias Hygeia.TenantContext.Tenant
  alias Surface.Components.Link
  alias Surface.Components.LivePatch
  alias Surface.Components.LiveRedirect

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    socket =
      if authorized?(Tenant, :list, get_auth(socket)) do
        Phoenix.PubSub.subscribe(Hygeia.PubSub, "tenants")

        assign(socket, tenants: list_tenants())
      else
        socket
        |> push_redirect(to: Routes.home_index_path(socket, :index))
        |> put_flash(:error, gettext("You are not authorized to do this action."))
      end

    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def handle_event("delete", %{"id" => id}, socket) do
    tenant = TenantContext.get_tenant!(id)

    true = authorized?(tenant, :delete, get_auth(socket))

    tenant
    |> TenantContext.delete_tenant()
    |> case do
      {:ok, _tenant} ->
        {:noreply, assign(socket, :tenants, list_tenants())}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, changeset_error_flash(socket, changeset)}
    end
  end

  @impl Phoenix.LiveView
  def handle_info({_type, %Tenant{}, _version}, socket) do
    {:noreply, assign(socket, :tenants, list_tenants())}
  end

  def handle_info(_other, socket), do: {:noreply, socket}

  defp list_tenants, do: TenantContext.list_tenants()
end
