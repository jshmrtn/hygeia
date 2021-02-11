defmodule HygeiaWeb.StatisticsLive.ChooseTenant do
  @moduledoc false

  use HygeiaWeb, :surface_view

  alias Hygeia.TenantContext
  alias Hygeia.TenantContext.Tenant
  alias Surface.Components.LiveRedirect

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    socket =
      if authorized?(Tenant, :list, get_auth(socket)) do
        assign(socket, tenants: list_tenants(socket))
      else
        socket
        |> push_redirect(to: Routes.home_path(socket, :index))
        |> put_flash(:error, gettext("You are not authorized to do this action."))
      end

    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def handle_info(_other, socket), do: {:noreply, socket}

  defp list_tenants(socket) do
    auth = get_auth(socket)

    Enum.filter(TenantContext.list_tenants(), &authorized?(&1, :statistics, auth))
  end
end
