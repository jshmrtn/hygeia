defmodule HygeiaWeb.StatisticsLive.DailyStatistics do
  @moduledoc false

  use HygeiaWeb, :surface_view

  alias Hygeia.StatisticsContext
  alias Hygeia.TenantContext
  alias HygeiaWeb.DateInput
  alias Surface.Components.Form

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    {:ok, socket,
     temporary_assigns: [
       active_isolation_cases_per_day: [],
       active_quarantine_cases_per_day: [],
       cumulative_index_case_end_reasons: [],
       cumulative_possible_index_case_end_reasons: [],
       new_cases_per_day: [],
       active_hospitalization_cases_per_day: [],
       active_complexity_cases_per_day: [],
       active_infection_place_cases_per_day: [],
       transmission_country_cases_per_day: []
     ]}
  end

  @impl Phoenix.LiveView
  def handle_params(%{"tenant_uuid" => tenant_uuid} = params, _uri, socket) do
    tenant = TenantContext.get_tenant!(tenant_uuid)

    socket =
      if authorized?(tenant, :statistics, get_auth(socket)) do
        Phoenix.PubSub.subscribe(Hygeia.PubSub, "statistics_active_isolation_cases_per_day")

        socket = assign(socket, :tenant, tenant)

        if is_nil(params["date"]) do
          date = Date.to_string(Date.utc_today())

          push_redirect(socket,
            to: Routes.statistics_daily_statistics_path(socket, :show, tenant, date)
          )
        else
          socket
          |> assign(date: Date.from_iso8601!(params["date"]))
          |> load_data
        end
      else
        socket
        |> push_redirect(to: Routes.home_index_path(socket, :index))
        |> put_flash(:error, gettext("You are not authorized to do this action."))
      end

    {:noreply, socket}
  end

  @impl Phoenix.LiveView
  def handle_event("params_change", %{"date" => ""}, socket) do
    {:noreply, socket}
  end

  def handle_event("params_change", %{"date" => date}, socket) do
    {:noreply,
     push_patch(socket,
       to: Routes.statistics_daily_statistics_path(socket, :show, socket.assigns.tenant, date)
     )}
  end

  @impl Phoenix.LiveView
  def handle_info(:refresh, socket) do
    {:noreply, load_data(socket)}
  end

  def handle_info(_other, socket), do: {:noreply, socket}

  defp load_data(%{assigns: %{tenant: tenant, date: date}} = socket) do
    assign(socket,
      active_isolation_cases_per_day:
        StatisticsContext.list_active_isolation_cases_per_day(tenant, date, date),
      active_quarantine_cases_per_day:
        StatisticsContext.list_active_quarantine_cases_per_day(tenant, date, date),
      cumulative_index_case_end_reasons:
        StatisticsContext.list_cumulative_index_case_end_reasons(tenant, date, date),
      cumulative_possible_index_case_end_reasons:
        StatisticsContext.list_cumulative_possible_index_case_end_reasons(tenant, date, date),
      new_cases_per_day: StatisticsContext.list_new_cases_per_day(tenant, date, date),
      active_hospitalization_cases_per_day:
        StatisticsContext.list_active_hospitalization_cases_per_day(tenant, date, date),
      active_complexity_cases_per_day:
        StatisticsContext.list_active_complexity_cases_per_day(tenant, date, date),
      active_infection_place_cases_per_day:
        StatisticsContext.list_active_infection_place_cases_per_day(tenant, date, date, false),
      transmission_country_cases_per_day:
        StatisticsContext.list_transmission_country_cases_per_day(tenant, date, date, false)
    )
  end
end
