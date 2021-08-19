defmodule HygeiaWeb.AutoTracingLive.End do
  @moduledoc false

  use HygeiaWeb, :surface_view

  alias Hygeia.CaseContext
  alias Hygeia.Helpers.Empty
  alias Hygeia.Repo
  alias Surface.Components.LiveRedirect

  @impl Phoenix.LiveView
  def handle_params(%{"case_uuid" => case_uuid} = _params, _uri, socket) do
    case =
      case_uuid
      |> CaseContext.get_case!()
      |> Repo.preload(person: [], auto_tracing: [])

    socket =
      if authorized?(case, :auto_tracing, get_auth(socket)) do
        assign(socket,
          case: case,
          case_changeset: CaseContext.change_case(case),
          person: case.person,
          person_changeset: CaseContext.change_person(case.person),
          auto_tracing: case.auto_tracing
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
    if not Empty.is_empty?(socket.assigns.person_changeset, [:suspected_duplicates_uuid]) do
      CaseContext.update_person(socket.assigns.person_changeset)
    end

    {:noreply, socket}
  end
end
