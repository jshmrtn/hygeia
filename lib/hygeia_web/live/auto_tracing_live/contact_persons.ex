defmodule HygeiaWeb.AutoTracingLive.ContactPersons do
  @moduledoc false

  use HygeiaWeb, :surface_view

  import HygeiaWeb.Helpers.AutoTracing, only: [get_next_step_route: 1]

  alias Hygeia.AutoTracingContext
  alias Hygeia.AutoTracingContext.AutoTracing
  alias Hygeia.CaseContext
  alias Hygeia.CaseContext.Case
  alias Hygeia.Repo
  alias Surface.Components.Form
  alias Surface.Components.Form.ErrorTag
  alias Surface.Components.Form.Field
  alias Surface.Components.Form.HiddenInput

  alias Surface.Components.Form.RadioButton
  alias Surface.Components.LiveRedirect

  @impl Phoenix.LiveView
  # credo:disable-for-next-line Credo.Check.Design.DuplicatedCode
  def handle_params(%{"case_uuid" => case_uuid} = _params, _uri, socket) do
    case = load_case(case_uuid)

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

        !AutoTracing.step_available?(case.auto_tracing, :contact_persons) ->
          push_redirect(socket,
            to: Routes.auto_tracing_auto_tracing_path(socket, :auto_tracing, case)
          )

        true ->
          assign(socket,
            case: case,
            person: case.person,
            auto_tracing: case.auto_tracing,
            auto_tracing_changeset: %Ecto.Changeset{
              AutoTracingContext.change_auto_tracing(case.auto_tracing, %{}, %{
                has_contact_persons_required: true
              })
              | action: :validate
            }
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
        AutoTracingContext.change_auto_tracing(
          socket.assigns.auto_tracing,
          %{
            has_contact_persons: has_contact_persons
          },
          %{has_contact_persons_required: true}
        )
        | action: :validate
      })

    {:ok, _} =
      AutoTracingContext.update_auto_tracing(
        %Ecto.Changeset{socket.assigns.auto_tracing_changeset | action: nil},
        %{},
        %{
          has_contact_persons_required: true
        }
      )

    {:noreply, socket}
  end

  @impl Phoenix.LiveView
  def handle_event("delete", %{"id" => id}, socket) do
    possible_index_submission = CaseContext.get_possible_index_submission!(id)

    true = authorized?(possible_index_submission, :delete, get_auth(socket))

    {:ok, _} = CaseContext.delete_possible_index_submission(possible_index_submission)

    case = load_case(socket.assigns.case.uuid)

    if Enum.empty?(case.possible_index_submissions) do
      AutoTracingContext.auto_tracing_remove_problem(
        case.auto_tracing,
        :possible_index_submission
      )
    end

    {:noreply, assign(socket, case: case)}
  end

  @impl Phoenix.LiveView
  def handle_event("advance", _params, socket) do
    {:ok, auto_tracing} =
      AutoTracingContext.update_auto_tracing(
        %Ecto.Changeset{socket.assigns.auto_tracing_changeset | action: nil},
        %{},
        %{
          has_contact_persons_required: true
        }
      )

    {:ok, _auto_tracing} = AutoTracingContext.advance_one_step(auto_tracing, :contact_persons)

    {:noreply,
     push_redirect(socket,
       to:
         get_next_step_route(:contact_persons).(
           socket,
           socket.assigns.auto_tracing.case_uuid
         )
     )}
  end

  defp load_case(case_uuid) do
    case_uuid
    |> CaseContext.get_case!()
    |> Repo.preload(person: [], auto_tracing: [], possible_index_submissions: [], tests: [])
  end
end
