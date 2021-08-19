defmodule HygeiaWeb.AutoTracingLive.AutoTracing do
  @moduledoc false

  use HygeiaWeb, :surface_view

  alias Hygeia.AutoTracingContext
  alias Hygeia.CaseContext
  alias Hygeia.Repo

  defp route(:start), do: &Routes.auto_tracing_start_path(&1, :start, &2)
  defp route(:address), do: &Routes.auto_tracing_address_path(&1, :address, &2)

  defp route(:contact_methods),
    do: &Routes.auto_tracing_contact_methods_path(&1, :contact_methods, &2)

  defp route(:employer), do: &Routes.auto_tracing_employer_path(&1, :employer, &2)
  defp route(:vaccination), do: &Routes.auto_tracing_vaccination_path(&1, :vaccination, &2)
  defp route(:covid_app), do: &Routes.auto_tracing_covid_app_path(&1, :covid_app, &2)
  defp route(:clinical), do: &Routes.auto_tracing_clinical_path(&1, :clinical, &2)
  defp route(:transmission), do: &Routes.auto_tracing_transmission_path(&1, :transmission, &2)
  defp route(:end), do: &Routes.auto_tracing_end_path(&1, :end, &2)

  @impl Phoenix.LiveView
  def render(assigns) do
    ~F"""
    nil
    """
  end

  @impl Phoenix.LiveView
  def handle_params(%{"case_uuid" => case_uuid} = _params, _uri, socket) do
    case =
      case_uuid
      |> CaseContext.get_case!()
      |> Repo.preload(person: [], tests: [:mutation], auto_tracing: [])

    socket =
      if authorized?(case, :auto_tracing, get_auth(socket)) do
        {:ok, auto_tracing} =
          case case.auto_tracing do
            nil ->
              AutoTracingContext.create_auto_tracing(case)

            auto_tracing ->
              {:ok, auto_tracing}
          end

        push_redirect(socket, to: route(auto_tracing.last_completed_step).(socket, case.uuid))
      else
        push_redirect(socket,
          to:
            Routes.auth_login_path(socket, :login,
              person_uuid: case.person_uuid,
              return_url: Routes.auto_tracing_auto_tracing_path(socket, :auto_tracing, case)
            )
        )
      end

    {:noreply, socket}
  end
end
