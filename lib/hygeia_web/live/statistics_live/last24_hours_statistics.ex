defmodule HygeiaWeb.StatisticsLive.Last24HoursStatistics do
  @moduledoc false

  use HygeiaWeb, :surface_view

  alias Hygeia.CaseContext.Case.Phase
  alias Hygeia.StatisticsContext
  alias Hygeia.TenantContext
  alias Surface.Components.Form
  alias Surface.Components.Form.Checkbox
  alias Surface.Components.Form.Field
  alias Surface.Components.Form.Label

  data enable_vision_impaired_mode, :boolean, default: false

  case Mix.env() do
    :dev -> @default_refresh_interval_ms :timer.seconds(30)
    _env -> @default_refresh_interval_ms :timer.minutes(5)
  end

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    :timer.send_interval(@default_refresh_interval_ms, :refresh)

    {:ok, socket,
     temporary_assigns: [
       last24hours_isolation_orders: 0,
       last24hours_quarantine_orders: [],
       last24hours_quarantine_converted_to_index: []
     ]}
  end

  @impl Phoenix.LiveView
  def handle_params(%{"tenant_uuid" => tenant_uuid} = _params, _uri, socket) do
    tenant = TenantContext.get_tenant!(tenant_uuid)

    socket =
      if authorized?(tenant, :statistics, get_auth(socket)) do
        socket
        |> assign(:tenant, tenant)
        |> assign(page_title: "#{tenant.name} - #{gettext("24 Hours Statistics")}")
        |> load_data()
      else
        socket
        |> push_redirect(to: Routes.home_index_path(socket, :index))
        |> put_flash(:error, gettext("You are not authorized to do this action."))
      end

    {:noreply, socket}
  end

  @impl Phoenix.LiveView
  def handle_event("params_change", params, socket) do
    {:noreply,
     assign(socket, enable_vision_impaired_mode: params["enable_vision_impaired_mode"] == "true")}
  end

  @impl Phoenix.LiveView
  def handle_info(:refresh, socket) do
    {:noreply, load_data(socket)}
  end

  def handle_info(_other, socket), do: {:noreply, socket}

  defp load_data(%{assigns: %{tenant: tenant}} = socket) do
    assign(socket,
      last24hours_isolation_orders: StatisticsContext.count_last24hours_isolation_orders(tenant),
      last24hours_quarantine_orders: StatisticsContext.list_last24hours_quarantine_orders(tenant),
      last24hours_quarantine_converted_to_index:
        StatisticsContext.list_last24hours_quarantine_converted_to_index(tenant)
    )
  end
end
