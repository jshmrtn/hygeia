defmodule HygeiaWeb.StatisticsLive.Export do
  @moduledoc false

  use HygeiaWeb, :surface_view

  alias Hygeia.StatisticsContext
  alias Hygeia.TenantContext
  alias HygeiaWeb.DateInput
  alias Surface.Components.Form
  alias Surface.Components.Form.DateInput
  alias Surface.Components.Link

  @impl Phoenix.LiveView
  def handle_params(%{"tenant_uuid" => tenant_uuid} = params, _uri, socket) do
    tenant = TenantContext.get_tenant!(tenant_uuid)

    socket =
      if authorized?(tenant, :statistics, get_auth(socket)) do
        socket = assign(socket, :tenant, tenant)

        if is_nil(params["from"]) or is_nil(params["to"]) do
          from = Date.utc_today() |> Date.add(-30) |> Date.to_string()
          to = Date.to_string(Date.utc_today())

          push_redirect(socket,
            to: Routes.statistics_export_path(socket, :show, tenant, from, to)
          )
        else
          assign(
            socket,
            from: Date.from_iso8601!(params["from"]),
            to: Date.from_iso8601!(params["to"])
          )
        end
      else
        socket
        |> push_redirect(to: Routes.home_index_path(socket, :index))
        |> put_flash(:error, gettext("You are not authorized to do this action."))
      end

    {:noreply, socket}
  end

  @impl Phoenix.LiveView
  def handle_event("params_change", %{"from" => ""}, socket) do
    {:noreply, socket}
  end

  def handle_event("params_change", %{"to" => ""}, socket) do
    {:noreply, socket}
  end

  def handle_event("params_change", %{"from" => from, "to" => to}, socket) do
    {:noreply,
     push_patch(socket,
       to: Routes.statistics_export_path(socket, :show, socket.assigns.tenant, from, to)
     )}
  end

  @impl Phoenix.LiveView
  def handle_info(_other, socket), do: {:noreply, socket}
end
