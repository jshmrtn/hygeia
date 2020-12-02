defmodule HygeiaWeb.StatisticsLive.Statistics do
  @moduledoc false

  use HygeiaWeb, :surface_view

  alias Hygeia.StatisticsContext
  alias Hygeia.TenantContext
  alias Surface.Components.Form
  alias Surface.Components.Form.DateInput

  @impl Phoenix.LiveView
  def mount(params, session, socket) do
    {:ok, socket} = super(params, session, socket)

    {:ok, socket, temporary_assigns: [active_isolation_cases_per_day: []]}
  end

  @impl Phoenix.LiveView
  def handle_params(%{"tenant_uuid" => tenant_uuid} = params, uri, socket) do
    tenant = TenantContext.get_tenant!(tenant_uuid)

    socket =
      if authorized?(tenant, :statistics, get_auth(socket)) do
        Phoenix.PubSub.subscribe(Hygeia.PubSub, "statistics_active_isolation_cases_per_day")

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
        |> push_redirect(to: Routes.home_path(socket, :index))
        |> put_flash(:error, gettext("You are not authorized to do this action."))
      end

    super(params, uri, socket)
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
       to: Routes.statistics_statistics_path(socket, :show, socket.assigns.tenant, from, to)
     )}
  end

  @impl Phoenix.LiveView
  def handle_info(:refresh, socket) do
    {:noreply, load_data(socket)}
  end

  def handle_info(_other, socket), do: {:noreply, socket}

  defp load_data(%{assigns: %{tenant: tenant, from: from, to: to}} = socket) do
    assign(socket,
      active_isolation_cases_per_day:
        StatisticsContext.list_active_isolation_cases_per_day(tenant, from, to),
      active_quarantine_cases_per_day:
        StatisticsContext.list_active_quarantine_cases_per_day(tenant, from, to),
      cumulative_index_case_end_reasons:
        StatisticsContext.list_cumulative_index_case_end_reasons(tenant, from, to),
      cumulative_possible_index_case_end_reasons:
        StatisticsContext.list_cumulative_possible_index_case_end_reasons(tenant, from, to),
      new_cases_per_day: StatisticsContext.list_new_cases_per_day(tenant, from, to),
      active_hospitalization_cases_per_day:
        StatisticsContext.list_active_hospitalization_cases_per_day(tenant, from, to),
      active_complexity_cases_per_day:
        StatisticsContext.list_active_complexity_cases_per_day(tenant, from, to),
      active_infection_place_cases_per_day:
        StatisticsContext.list_active_infection_place_cases_per_day(tenant, from, to)
    )
  end
end
