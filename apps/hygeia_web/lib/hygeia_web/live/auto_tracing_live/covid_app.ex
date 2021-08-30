defmodule HygeiaWeb.AutoTracingLive.CovidApp do
  @moduledoc false

  use HygeiaWeb, :surface_view

  alias Hygeia.AutoTracingContext
  alias Hygeia.AutoTracingContext.AutoTracing
  alias Hygeia.CaseContext
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
    case =
      case_uuid
      |> CaseContext.get_case!()
      |> Repo.preload(person: [], auto_tracing: [])

    socket =
      if authorized?(case, :auto_tracing, get_auth(socket)) do
        assign(socket,
          case: case,
          person: case.person,
          auto_tracing: case.auto_tracing,
          auto_tracing_changeset: %Ecto.Changeset{
            AutoTracingContext.change_auto_tracing(case.auto_tracing, %{}, %{
              covid_app_required: true
            })
            | action: :validate
          }
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
  def handle_event("validate", %{"auto_tracing" => auto_tracing_params}, socket) do
    socket =
      assign(socket, :auto_tracing_changeset, %Ecto.Changeset{
        AutoTracingContext.change_auto_tracing(
          socket.assigns.auto_tracing,
          auto_tracing_params,
          %{covid_app_required: true}
        )
        | action: :validate
      })

    {:noreply, socket}
  end

  @impl Phoenix.LiveView
  def handle_event("advance", _params, socket) do
    {:ok, auto_tracing} =
      AutoTracingContext.update_auto_tracing(
        %Ecto.Changeset{socket.assigns.auto_tracing_changeset | action: nil},
        %{},
        %{covid_app_required: true}
      )

    {:ok, auto_tracing} =
      case auto_tracing do
        %AutoTracing{covid_app: true} ->
          AutoTracingContext.auto_tracing_add_problem_if_not_exists(
            socket.assigns.auto_tracing,
            :covid_app
          )

        %AutoTracing{} ->
          AutoTracingContext.auto_tracing_remove_problem(
            socket.assigns.auto_tracing,
            :covid_app
          )
      end

    {:ok, _auto_tracing} = AutoTracingContext.advance_one_step(auto_tracing, :covid_app)

    {:noreply,
     push_redirect(socket,
       to:
         Routes.auto_tracing_clinical_path(
           socket,
           :clinical,
           socket.assigns.auto_tracing.case_uuid
         )
     )}
  end
end
