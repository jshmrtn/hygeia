defmodule HygeiaWeb.AutoTracingLive.Vaccination do
  @moduledoc false

  use HygeiaWeb, :surface_view

  alias Hygeia.AutoTracingContext
  alias Hygeia.CaseContext
  alias Hygeia.CaseContext.Person
  alias Hygeia.Repo

  alias Surface.Components.Form
  alias Surface.Components.Form.DateInput
  alias Surface.Components.Form.ErrorTag
  alias Surface.Components.Form.Field
  alias Surface.Components.Form.Input.InputContext
  alias Surface.Components.Form.Inputs
  alias Surface.Components.Form.RadioButton
  alias Surface.Components.Form.TextInput
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

  def handle_event(
        "add_vaccination_jab_date",
        _params,
        %{assigns: %{person_changeset: person_changeset, person: person}} = socket
      ) do
    vaccination_params =
      person_changeset
      |> Ecto.Changeset.get_change(
        :vaccination,
        Person.Vaccination.changeset(
          Ecto.Changeset.get_field(person_changeset, :vaccination, %Person.Vaccination{}),
          %{}
        )
      )
      |> update_changeset_param(
        :jab_dates,
        &(&1 |> Kernel.||([]) |> Enum.concat([nil]) |> Enum.uniq())
      )

    params =
      update_changeset_param(person_changeset, :vaccination, fn _input -> vaccination_params end)

    {:noreply, assign(socket, :person_changeset, CaseContext.change_person(person, params))}
  end

  def handle_event(
        "remove_vaccination_jab_date",
        %{"index" => index} = _params,
        %{assigns: %{person_changeset: person_changeset, person: person}} = socket
      ) do
    index = String.to_integer(index)

    vaccination_params =
      person_changeset
      |> Ecto.Changeset.get_change(
        :vaccination,
        Person.Vaccination.changeset(
          Ecto.Changeset.get_field(person_changeset, :vaccination, %Person.Vaccination{}),
          %{}
        )
      )
      |> update_changeset_param(:jab_dates, &List.delete_at(&1, index))

    params =
      update_changeset_param(person_changeset, :vaccination, fn _input -> vaccination_params end)

    {:noreply, assign(socket, :person_changeset, CaseContext.change_person(person, params))}
  end

  def handle_event("validate", %{"person" => person_params}, socket) do
    person_params =
      Map.update(person_params, "vaccination", %{"jab_dates" => []}, fn vaccination ->
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

  @impl Phoenix.LiveView
  def handle_event("advance", _params, socket) do
    {:ok, person} = CaseContext.update_person(socket.assigns.person_changeset)

    {:ok, auto_tracing} =
      case person do
        %Person{vaccination: %Person.Vaccination{done: true}} ->
          AutoTracingContext.auto_tracing_add_problem(
            socket.assigns.auto_tracing,
            :vaccination_failure
          )

        %Person{} ->
          AutoTracingContext.auto_tracing_remove_problem(
            socket.assigns.auto_tracing,
            :vaccination_failure
          )
      end

    {:ok, _auto_tracing} = AutoTracingContext.advance_one_step(auto_tracing, :vaccination)

    {:noreply,
     push_redirect(socket,
       to:
         Routes.auto_tracing_covid_app_path(
           socket,
           :covid_app,
           socket.assigns.auto_tracing.case_uuid
         )
     )}
  end
end
