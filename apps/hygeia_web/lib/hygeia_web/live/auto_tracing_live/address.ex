defmodule HygeiaWeb.AutoTracingLive.Address do
  @moduledoc false

  use HygeiaWeb, :surface_view

  alias Hygeia.AutoTracingContext
  alias Hygeia.CaseContext
  alias Hygeia.Helpers.Empty
  alias Hygeia.Repo
  alias Surface.Components.LiveRedirect

  alias Surface.Components.Form
  alias Surface.Components.Form.Inputs

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
  def handle_event(
        "validate",
        %{"person" => %{"address" => address}},
        socket
      ) do
    socket =
      assign(socket, :person_changeset, %{
        CaseContext.change_person(socket.assigns.person, %{address: address})
        | action: :update
      })

    {:noreply, socket}
  end

  def handle_event(
        "validate",
        %{"case" => %{"monitoring" => monitoring}},
        socket
      ) do
    socket =
      assign(socket, :case_changeset, %{
        CaseContext.change_case(socket.assigns.case, %{monitoring: monitoring})
        | action: :update
      })

    {:noreply, socket}
  end

  def handle_event("advance", _params, socket) do
    if not Empty.is_empty?(socket.assigns.case_changeset, []) do
      CaseContext.update_case(socket.assigns.case_changeset)
    end

    if not Empty.is_empty?(socket.assigns.person_changeset, [:suspected_duplicates_uuid]) do
      CaseContext.update_person(socket.assigns.person_changeset)
    end

    {:ok, _auto_tracing} =
      AutoTracingContext.advance_one_step(socket.assigns.auto_tracing, :address)

    {:noreply,
     push_redirect(socket,
       to:
         Routes.auto_tracing_contact_methods_path(
           socket,
           :contact_methods,
           socket.assigns.auto_tracing.case_uuid
         )
     )}
  end
end
