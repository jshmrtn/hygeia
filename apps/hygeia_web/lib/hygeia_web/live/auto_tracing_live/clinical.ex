defmodule HygeiaWeb.AutoTracingLive.Clinical do
  @moduledoc false

  use HygeiaWeb, :surface_view

  alias Hygeia.AutoTracingContext
  alias Hygeia.CaseContext
  alias Hygeia.Helpers.Empty
  alias Hygeia.OrganisationContext
  alias Hygeia.Repo

  alias Surface.Components.Form
  alias Surface.Components.Form.DateInput
  alias Surface.Components.Form.ErrorTag
  alias Surface.Components.Form.Field
  alias Surface.Components.Form.Input.InputContext
  alias Surface.Components.Form.Inputs
  alias Surface.Components.Form.RadioButton

  @impl Phoenix.LiveView
  def handle_params(%{"case_uuid" => case_uuid} = _params, _uri, socket) do
    case =
      case_uuid
      |> CaseContext.get_case!()
      |> Repo.preload(person: [], hospitalizations: [organisation: []])

    socket =
      if authorized?(case, :auto_tracing, get_auth(socket)) do
        auto_tracing = AutoTracingContext.get_auto_tracing_by_case(case)
        organisations = OrganisationContext.list_organisations()

        assign(socket,
          case: case,
          case_changeset: CaseContext.change_case(case),
          person: case.person,
          auto_tracing: auto_tracing,
          organisations: organisations
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
  def handle_event("validate", %{"case" => case_params}, socket) do
    case_params = Map.put_new(case_params, "hospitalizations", [])

    {:noreply,
     assign(socket, :case_changeset, %{
       CaseContext.change_case(socket.assigns.case, case_params)
       | action: :update
     })}
  end

  def handle_event(
        "add_hospitalization",
        _params,
        %{assigns: %{case_changeset: case_changeset, case: case}} = socket
      ) do
    {:noreply,
     assign(
       socket,
       :case_changeset,
       CaseContext.change_case(
         case,
         changeset_add_to_params(case_changeset, :hospitalizations, %{uuid: Ecto.UUID.generate()})
       )
     )}
  end

  def handle_event(
        "remove_hospitalization",
        %{"changeset-uuid" => uuid} = _params,
        %{assigns: %{case_changeset: case_changeset, case: case}} = socket
      ) do
    {:noreply,
     assign(
       socket,
       :case_changeset,
       CaseContext.change_case(
         case,
         changeset_remove_from_params_by_id(case_changeset, :hospitalizations, %{uuid: uuid})
       )
     )}
  end

  def handle_event("advance", _params, socket) do
    if not Empty.is_empty?(socket.assigns.case_changeset, []) do
      CaseContext.update_case(socket.assigns.case_changeset)
    end

    {:ok, _auto_tracing} =
      AutoTracingContext.advance_one_step(socket.assigns.auto_tracing, :clinical)

    {:noreply,
     push_redirect(socket,
       to:
         Routes.auto_tracing_transmission_path(
           socket,
           :transmission,
           socket.assigns.auto_tracing.case_uuid
         )
     )}
  end

  @impl Phoenix.LiveView
  def handle_info(
        {:hospitalisation_change_organisation, uuid, organisation_uuid},
        %{assigns: %{case_changeset: case_changeset, case: case}} = socket
      ) do
    {:noreply,
     assign(
       socket,
       :case_changeset,
       CaseContext.change_case(
         case,
         changeset_update_params_by_id(
           case_changeset,
           :hospitalizations,
           %{uuid: uuid},
           &Map.put(&1, "organisation_uuid", organisation_uuid)
         )
       )
     )}
  end

  def handle_info(_other, socket), do: {:noreply, socket}
end
