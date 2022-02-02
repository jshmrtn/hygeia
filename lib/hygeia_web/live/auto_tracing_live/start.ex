defmodule HygeiaWeb.AutoTracingLive.Start do
  @moduledoc false

  use HygeiaWeb, :surface_view

  import HygeiaWeb.Helpers.AutoTracing, only: [get_next_step_route: 1]

  alias Hygeia.AutoTracingContext
  alias Hygeia.CaseContext
  alias Hygeia.CaseContext.Case
  alias Hygeia.CaseContext.Test
  alias Hygeia.CaseContext.Test.Kind
  alias Hygeia.CaseContext.Test.Result
  alias Hygeia.Repo
  alias HygeiaWeb.Helpers.Tenant, as: TenantHelper
  alias Surface.Components.Link

  @impl Phoenix.LiveView
  def handle_params(%{"case_uuid" => case_uuid} = _params, _uri, socket) do
    case =
      case_uuid
      |> CaseContext.get_case!()
      |> Repo.preload(person: [], tests: [:mutation], auto_tracing: [], tenant: [])

    socket =
      cond do
        Case.closed?(case) ->
          raise HygeiaWeb.AutoTracingLive.AutoTracing.CaseClosedError, case_uuid: case.uuid

        !authorized?(case, :auto_tracing, get_auth(socket)) ->
          push_redirect(socket,
            to:
              Routes.auth_login_path(socket, :login,
                person_uuid: case.person_uuid,
                return_url: Routes.auto_tracing_auto_tracing_path(socket, :auto_tracing, case)
              )
          )

        true ->
          assign(socket,
            case: case,
            person: case.person,
            auto_tracing: case.auto_tracing
          )
      end

    {:noreply, socket}
  end

  @impl Phoenix.LiveView
  def handle_event("advance", _params, socket) do
    {:ok, _auto_tracing} =
      AutoTracingContext.advance_one_step(socket.assigns.auto_tracing, :start)

    if is_nil(socket.assigns.case.monitoring) or
         is_nil(socket.assigns.case.monitoring.first_contact) do
      {:ok, _case} =
        CaseContext.update_case(socket.assigns.case, %{
          monitoring: %{first_contact: DateTime.utc_now()}
        })
    end

    {:noreply,
     push_redirect(socket,
       to: get_next_step_route(:start).(socket, socket.assigns.auto_tracing.case_uuid)
     )}
  end

  defp format_date(nil), do: nil
  defp format_date(date), do: HygeiaCldr.Date.to_string!(date)
end
