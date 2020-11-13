defmodule HygeiaWeb.StatisticsLive.Statistics do
  @moduledoc false

  use HygeiaWeb, :surface_view

  alias Contex.BarChart
  alias Contex.Dataset
  alias Contex.Plot
  alias Hygeia.CaseContext
  alias Hygeia.TenantContext
  alias HygeiaWeb.StatisticsLive.StatPanel
  alias Surface.Components.Form
  alias Surface.Components.Form.DateInput

  @impl Phoenix.LiveView
  def handle_params(%{"tenant_uuid" => tenant_uuid} = params, uri, socket) do
    tenant = TenantContext.get_tenant!(tenant_uuid)

    socket =
      if authorized?(tenant, :statistics, get_auth(socket)) do
        socket = assign(socket, :tenant, tenant)

        if is_nil(params["from"]) or is_nil(params["to"]) do
          from = Date.utc_today() |> Date.add(-30) |> Date.to_string()
          to = Date.to_string(Date.utc_today())

          push_redirect(socket,
            to: Routes.statistics_statistics_path(socket, :show, tenant, from, to)
          )
        else
          socket
          |> assign(
            from: Date.from_iso8601!(params["from"]),
            to: Date.from_iso8601!(params["to"])
          )
          |> load_data
        end
      else
        socket
        |> push_redirect(to: Routes.page_path(socket, :index))
        |> put_flash(:error, gettext("You are not authorized to do this action."))
      end

    super(params, uri, socket)
  end

  @impl Phoenix.LiveView
  def handle_event("params_change", %{"from" => from, "to" => to}, socket) do
    {:noreply,
     push_patch(socket,
       to: Routes.statistics_statistics_path(socket, :show, socket.assigns.tenant, from, to)
     )}
  end

  defp load_data(%{assigns: %{tenant: tenant, from: from, to: to}} = socket) do
    assign(socket,
      active_isolation_cases_per_day: CaseContext.active_isolation_cases_per_day(tenant, from, to)
    )
  end

  defp basic_plot(data) do
    data
    |> Enum.map(fn {date, count} ->
      {Date.to_iso8601(date), count}
    end)
    |> Dataset.new(["date", "count"])
    |> Plot.new(BarChart, 500, 400)
    |> Plot.titles("Isolations", "per day")
    |> Plot.axis_labels("date", "isolations")
    |> Plot.to_svg()
  end
end
