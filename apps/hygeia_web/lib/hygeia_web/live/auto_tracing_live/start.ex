defmodule HygeiaWeb.AutoTracingLive.Start do
  @moduledoc false

  use HygeiaWeb, :surface_view

  alias Hygeia.AutoTracingContext
  alias Hygeia.CaseContext
  alias Hygeia.CaseContext.Test.Kind
  alias Hygeia.CaseContext.Test.Result
  alias Hygeia.Repo

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
              AutoTracingContext.create_auto_tracing(case, %{
                current_step: :start,
                last_completed_step: :start
              })

            auto_tracing ->
              {:ok, auto_tracing}
          end

        assign(socket,
          case: case,
          person: case.person,
          auto_tracing: auto_tracing
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

  @impl Phoenix.LiveView
  def handle_event("advance", _params, socket) do
    {:ok, _auto_tracing} =
      AutoTracingContext.advance_one_step(socket.assigns.auto_tracing, :start)

    {:noreply,
     push_redirect(socket,
       to:
         Routes.auto_tracing_address_path(socket, :address, socket.assigns.auto_tracing.case_uuid)
     )}
  end

  defp format_date(nil), do: nil
  defp format_date(date), do: HygeiaCldr.Date.to_string!(date)
end
