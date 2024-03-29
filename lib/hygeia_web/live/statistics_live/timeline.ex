defmodule HygeiaWeb.StatisticsLive.Timeline do
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

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    {:ok, socket,
     temporary_assigns: [
       active_isolation_cases_per_day: [],
       active_quarantine_cases_per_day: [],
       cumulative_index_case_end_reasons: [],
       cumulative_possible_index_case_end_reasons: [],
       new_cases_per_day: [],
       hospital_admission_cases_per_day: [],
       active_complexity_cases_per_day: [],
       active_infection_place_cases_per_day: [],
       transmission_country_cases_per_day: [],
       new_registered_cases_per_day_first_contact: [],
       new_registered_cases_per_day_not_first_contact: [],
       vaccination_breakthroughs_per_day: []
     ]}
  end

  @impl Phoenix.LiveView
  def handle_params(%{"tenant_uuid" => tenant_uuid} = params, _uri, socket) do
    tenant = TenantContext.get_tenant!(tenant_uuid)

    socket =
      if authorized?(tenant, :statistics, get_auth(socket)) do
        Phoenix.PubSub.subscribe(Hygeia.PubSub, "statistics_active_isolation_cases_per_day")

        socket = assign(socket, :tenant, tenant)

        socket = assign(socket, page_title: "#{tenant.name} - #{gettext("Statistics")}")

        with from when is_binary(from) <- params["from"],
             to when is_binary(from) <- params["to"],
             {:ok, from} <- Date.from_iso8601(from),
             {:ok, to} <- Date.from_iso8601(to) do
          socket
          |> assign(from: from, to: to)
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
  def handle_event("params_change", %{} = params, socket) do
    {:noreply,
     socket
     |> assign(enable_vision_impaired_mode: params["enable_vision_impaired_mode"] == "true")
     |> Context.put(HygeiaWeb.Chart,
       enable_vision_impaired_mode: params["enable_vision_impaired_mode"] == "true"
     )
     |> push_patch(
       to:
         Routes.statistics_timeline_path(
           socket,
           :show,
           socket.assigns.tenant,
           case params["from"] do
             "" -> Date.to_iso8601(socket.assigns.from)
             nil -> Date.to_iso8601(socket.assigns.from)
             date -> date
           end,
           case params["to"] do
             "" -> Date.to_iso8601(socket.assigns.to)
             nil -> Date.to_iso8601(socket.assigns.to)
             date -> date
           end
         )
     )}
  end

  @impl Phoenix.LiveView
  def handle_info(:refresh, socket) do
    {:noreply, load_data(socket)}
  end

  def handle_info(_other, socket), do: {:noreply, socket}

  defp fallback_redirect(socket, tenant) do
    from = Date.utc_today() |> Date.add(-30) |> Date.to_string()
    to = Date.to_string(Date.utc_today())

    push_redirect(socket,
      to: Routes.statistics_timeline_path(socket, :show, tenant, from, to)
    )
  end

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
      hospital_admission_cases_per_day:
        StatisticsContext.list_hospital_admission_cases_per_day(tenant, from, to),
      active_complexity_cases_per_day:
        StatisticsContext.list_active_complexity_cases_per_day(tenant, from, to),
      active_infection_place_cases_per_day:
        StatisticsContext.list_active_infection_place_cases_per_day(tenant, from, to),
      transmission_country_cases_per_day:
        StatisticsContext.list_transmission_country_cases_per_day(tenant, from, to),
      new_registered_cases_per_day_first_contact:
        StatisticsContext.list_new_registered_cases_per_day(tenant, from, to, true),
      new_registered_cases_per_day_not_first_contact:
        StatisticsContext.list_new_registered_cases_per_day(tenant, from, to, false),
      vaccination_breakthroughs_per_day:
        StatisticsContext.list_vaccination_breakthroughs_per_day(tenant, from, to)
    )
  end
end
