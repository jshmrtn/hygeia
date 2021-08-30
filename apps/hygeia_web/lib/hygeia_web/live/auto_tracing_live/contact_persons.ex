defmodule HygeiaWeb.AutoTracingLive.ContactPersons do
  @moduledoc false

  use HygeiaWeb, :surface_view

  alias Hygeia.AutoTracingContext
  alias Hygeia.CaseContext
  alias Hygeia.CaseContext.PossibleIndexSubmission
  alias Hygeia.Repo
  alias Surface.Components.Form
  alias Surface.Components.Form.ErrorTag
  alias Surface.Components.Form.Field
  alias Surface.Components.Form.Input.InputContext
  alias Surface.Components.Form.RadioButton
  alias Surface.Components.LiveRedirect

  @impl Phoenix.LiveView
  # credo:disable-for-next-line Credo.Check.Design.DuplicatedCode
  def handle_params(%{"case_uuid" => case_uuid} = _params, _uri, socket) do
    case = load_case(case_uuid)

    socket =
      if authorized?(case, :auto_tracing, get_auth(socket)) do
        assign(socket,
          case: case,
          person: case.person,
          auto_tracing: case.auto_tracing,
          auto_tracing_changeset: AutoTracingContext.change_auto_tracing(case.auto_tracing)
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
        %{"auto_tracing" => %{"has_contact_persons" => has_contact_persons}},
        socket
      ) do
    socket =
      assign(socket, :auto_tracing_changeset, %Ecto.Changeset{
        AutoTracingContext.change_auto_tracing(socket.assigns.auto_tracing, %{
          has_contact_persons: has_contact_persons
        })
        | action: :update
      })

    {:noreply, socket}
  end

  @impl Phoenix.LiveView
  def handle_event("delete", %{"id" => id}, socket) do
    possible_index_submission = CaseContext.get_possible_index_submission!(id)

    true = authorized?(possible_index_submission, :delete, get_auth(socket))

    {:ok, _} = CaseContext.delete_possible_index_submission(possible_index_submission)

    {:noreply, assign(socket, case: load_case(socket.assigns.case.uuid))}
  end

  @impl Phoenix.LiveView
  def handle_event("advance", _params, socket) do
    {:ok, auto_tracing} =
      AutoTracingContext.update_auto_tracing(socket.assigns.auto_tracing_changeset)

    {:ok, _auto_tracing} = AutoTracingContext.advance_one_step(auto_tracing, :contact_persons)

    {:noreply,
     push_redirect(socket,
       to:
         Routes.auto_tracing_end_path(
           socket,
           :end,
           socket.assigns.auto_tracing.case_uuid
         )
     )}
  end

  defp load_case(case_uuid) do
    case_uuid
    |> CaseContext.get_case!()
    |> Repo.preload(person: [], auto_tracing: [], possible_index_submissions: [])
  end
end
