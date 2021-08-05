# credo:disable-for-this-file Credo.Check.Refactor.CyclomaticComplexity
defmodule HygeiaWeb.AutoTracingLive.AutoTracing do
  @moduledoc false

  use HygeiaWeb, :surface_view

  alias Hygeia.AutoTracingContext
  alias Hygeia.CaseContext
  alias Hygeia.Repo

  @impl Phoenix.LiveView
  def render(assigns) do
    ~F"""

    """
  end

  @impl Phoenix.LiveView
  def handle_params(%{"case_uuid" => case_uuid} = _params, _uri, socket) do
    case =
      case_uuid
      |> CaseContext.get_case!()
      |> Repo.preload(person: [], tests: [:mutation])

    socket =
      if authorized?(case, :auto_tracing, get_auth(socket)) do
        {:ok, auto_tracing} =
          case AutoTracingContext.get_auto_tracing_by_case(case) do
            nil ->
              AutoTracingContext.create_auto_tracing(case)

            auto_tracing ->
              {:ok, auto_tracing}
          end

        push_redirect(socket,
          to:
            case auto_tracing.last_completed_step do
              :start ->
                Routes.auto_tracing_start_path(socket, :start, case.uuid)

              :address ->
                Routes.auto_tracing_address_path(socket, :address, case.uuid)

              :contact_methods ->
                Routes.auto_tracing_contact_methods_path(socket, :contact_methods, case.uuid)

              :employer ->
                Routes.auto_tracing_employer_path(socket, :employer, case.uuid)

              :vaccination ->
                Routes.auto_tracing_vaccination_path(socket, :vaccination, case.uuid)

              :covid_app ->
                Routes.auto_tracing_covid_app_path(socket, :covid_app, case.uuid)

              :clinical ->
                Routes.auto_tracing_clinical_path(socket, :clinical, case.uuid)

              :transmission ->
                Routes.auto_tracing_transmission_path(socket, :transmission, case.uuid)

              :end ->
                Routes.auto_tracing_end_path(socket, :end, case.uuid)
            end
        )
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
