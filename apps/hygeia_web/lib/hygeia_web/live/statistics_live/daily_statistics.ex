defmodule HygeiaWeb.StatisticsLive.DailyStatistics do
  @moduledoc false

  use HygeiaWeb, :surface_view

  alias Hygeia.CaseContext.Case
  alias Hygeia.CaseContext.Case.Phase
  alias Hygeia.StatisticsContext
  alias Hygeia.TenantContext
  alias HygeiaWeb.DateInput
  alias Surface.Components.Form
  alias Surface.Components.Form.Checkbox
  alias Surface.Components.Form.Field
  alias Surface.Components.Form.Label

  data enable_vision_impaired_mode, :boolean, default: false
  data infection_table_modal_open, :boolean, default: false
  data country_table_modal_open, :boolean, default: false
  data organisation_table_modal_open, :boolean, default: false

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
       transmission_country_cases_per_day: [],
       active_cases_per_day_and_organisation: []
     ]}
  end

  @impl Phoenix.LiveView
  def handle_params(%{"tenant_uuid" => tenant_uuid} = params, _uri, socket) do
    tenant = TenantContext.get_tenant!(tenant_uuid)

    socket =
      if authorized?(tenant, :statistics, get_auth(socket)) do
        Phoenix.PubSub.subscribe(Hygeia.PubSub, "statistics_active_isolation_cases_per_day")

        socket = assign(socket, :tenant, tenant)

        socket = assign(socket, page_title: "#{tenant.name} - #{gettext("Daily Statistics")}")

        with date when is_binary(date) <- params["date"],
             {:ok, date} <- Date.from_iso8601(date) do
          socket
          |> assign(date: date)
          |> load_data
        else
          nil -> fallback_redirect(socket, tenant)
          {:error, :invalid_format} -> fallback_redirect(socket, tenant)
        end
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
     socket
     |> assign(enable_vision_impaired_mode: params["enable_vision_impaired_mode"] == "true")
     |> push_patch(
       to:
         Routes.statistics_daily_statistics_path(
           socket,
           :show,
           socket.assigns.tenant,
           case params["date"] do
             "" -> Date.to_iso8601(socket.assigns.date)
             nil -> Date.to_iso8601(socket.assigns.date)
             date -> date
           end
         )
     )}
  end

  def handle_event("open_infection_table_modal", _params, socket) do
    {:noreply, socket |> assign(infection_table_modal_open: true) |> load_data()}
  end

  def handle_event("close_infection_table_modal", _params, socket) do
    {:noreply, socket |> assign(infection_table_modal_open: false) |> load_data()}
  end

  def handle_event("open_country_table_modal", _params, socket) do
    {:noreply, socket |> assign(country_table_modal_open: true) |> load_data()}
  end

  def handle_event("close_country_table_modal", _params, socket) do
    {:noreply, socket |> assign(country_table_modal_open: false) |> load_data()}
  end

  def handle_event("open_organisation_table_modal", _params, socket) do
    {:noreply, socket |> assign(organisation_table_modal_open: true) |> load_data()}
  end

  def handle_event("close_organisation_table_modal", _params, socket) do
    {:noreply, socket |> assign(organisation_table_modal_open: false) |> load_data()}
  end

  @impl Phoenix.LiveView
  def handle_info(:refresh, socket) do
    {:noreply, load_data(socket)}
  end

  def handle_info(_other, socket), do: {:noreply, socket}

  defp fallback_redirect(socket, tenant) do
    date = Date.to_string(Date.utc_today())

    push_redirect(socket,
      to: Routes.statistics_daily_statistics_path(socket, :show, tenant, date)
    )
  end

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
        StatisticsContext.list_transmission_country_cases_per_day(tenant, date, date, false),
      active_cases_per_day_and_organisation:
        StatisticsContext.list_active_cases_per_day_and_organisation(tenant, date, date)
    )
  end
end
