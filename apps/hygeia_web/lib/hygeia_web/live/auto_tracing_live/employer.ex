defmodule HygeiaWeb.AutoTracingLive.Employer do
  @moduledoc false

  use HygeiaWeb, :surface_view

  alias Hygeia.AutoTracingContext
  alias Hygeia.CaseContext
  alias Hygeia.Helpers.Empty
  alias Hygeia.Repo

  alias Surface.Components.Form
  alias Surface.Components.Form.ErrorTag
  alias Surface.Components.Form.Field
  alias Surface.Components.Form.HiddenInput
  alias Surface.Components.Form.Input.InputContext
  alias Surface.Components.Form.Inputs
  alias Surface.Components.Form.Select
  alias Surface.Components.Form.TextInput

  @impl Phoenix.LiveView
  def handle_params(%{"case_uuid" => case_uuid} = _params, _uri, socket) do
    case =
      case_uuid
      |> CaseContext.get_case!()
      |> Repo.preload(person: [:affiliations])

    socket =
      if authorized?(case, :auto_tracing, get_auth(socket)) do
        auto_tracing = AutoTracingContext.get_auto_tracing_by_case(case)

        person_changeset = CaseContext.change_person(case.person)

        person_changeset =
          case case.person.affiliations do
            [] ->
              CaseContext.change_person(
                case.person,
                changeset_add_to_params(person_changeset, :affiliations, %{
                  uuid: Ecto.UUID.generate()
                })
              )

            _other ->
              person_changeset
          end

        assign(socket,
          case: case,
          person: case.person,
          person_changeset: person_changeset,
          auto_tracing: auto_tracing,
          auto_tracing_changeset: AutoTracingContext.change_auto_tracing(auto_tracing)
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
        "select_affiliation_organisation",
        %{"subject" => affiliation_uuid} = params,
        %{assigns: %{person_changeset: person_changeset, person: person}} = socket
      ) do
    {:noreply,
     assign(
       socket,
       :person_changeset,
       CaseContext.change_person(
         person,
         changeset_update_params_by_id(
           person_changeset,
           :affiliations,
           %{uuid: affiliation_uuid},
           &Map.put(&1, "organisation_uuid", params["uuid"])
         )
       )
     )}
  end

  def handle_event("validate", %{"person" => person_params}, socket) do
    person_params =
      person_params
      |> Map.put_new("affiliations", [])
      |> Map.put_new("contact_methods", [])
      |> Map.put_new("external_references", [])
      |> Map.update("vaccination", %{"jab_dates" => []}, fn vaccination ->
        Map.update(
          vaccination,
          "jab_dates",
          [],
          &Enum.map(&1, fn
            "" -> nil
            other -> other
          end)
        )
      end)

    {:noreply,
     assign(socket, :person_changeset, %{
       CaseContext.change_person(socket.assigns.person, person_params)
       | action: :update
     })}
  end

  def handle_event("validate", %{"auto_tracing" => %{"employer" => employer}}, socket) do
    socket =
      assign(socket, :auto_tracing_changeset, %{
        AutoTracingContext.change_auto_tracing(socket.assigns.auto_tracing, %{
          employer: employer
        })
        | action: :update
      })

    {:noreply, socket}
  end

  @impl Phoenix.LiveView
  def handle_event("advance", _params, socket) do
    if not Empty.is_empty?(socket.assigns.person_changeset, [:suspected_duplicates_uuid]) do
      CaseContext.update_person(socket.assigns.person_changeset)
    end

    auto_tracing =
      if Empty.is_empty?(socket.assigns.auto_tracing_changeset, []) do
        socket.assigns.auto_tracing
      else
        {:ok, auto_tracing} =
          AutoTracingContext.update_auto_tracing(socket.assigns.auto_tracing_changeset)

        auto_tracing
      end

    {:ok, _auto_tracing} = AutoTracingContext.advance_one_step(auto_tracing, :employer)

    {:noreply,
     push_redirect(socket,
       to:
         Routes.auto_tracing_vaccination_path(
           socket,
           :vaccination,
           socket.assigns.auto_tracing.case_uuid
         )
     )}
  end
end
