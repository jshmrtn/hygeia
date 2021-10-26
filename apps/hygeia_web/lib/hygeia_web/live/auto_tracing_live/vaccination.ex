defmodule HygeiaWeb.AutoTracingLive.Vaccination do
  @moduledoc false

  use HygeiaWeb, :surface_view

  alias Hygeia.AutoTracingContext
  alias Hygeia.AutoTracingContext.AutoTracing
  alias Hygeia.CaseContext
  alias Hygeia.CaseContext.Case
  alias Hygeia.CaseContext.Person
  alias Hygeia.Repo

  alias Surface.Components.Form
  alias Surface.Components.Form.ErrorTag
  alias Surface.Components.Form.Field
  alias Surface.Components.Form.Input.InputContext
  alias Surface.Components.Form.Inputs
  alias Surface.Components.Form.RadioButton
  alias Surface.Components.LiveRedirect

  @impl Phoenix.LiveView
  def handle_params(%{"case_uuid" => case_uuid} = _params, _uri, socket) do
    case =
      case_uuid
      |> CaseContext.get_case!()
      |> Repo.preload(person: [], auto_tracing: [])

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

        !AutoTracing.step_available?(case.auto_tracing, :vaccination) ->
          push_redirect(socket,
            to: Routes.auto_tracing_auto_tracing_path(socket, :auto_tracing, case)
          )

        true ->
          assign(socket,
            case: case,
            person: case.person,
            changeset: %Ecto.Changeset{
              CaseContext.change_person(case.person, %{}, %{vaccination_required: true, clean_nil_jab_dates: true})
              | action: :validate
            },
            auto_tracing: case.auto_tracing
          )
      end

    {:noreply, socket}
  end

  def handle_event(
        "add_vaccination_jab_date",
        _params,
        %{assigns: %{changeset: changeset, person: person}} = socket
      ) do
    vaccination_params =
      changeset
      |> Ecto.Changeset.get_change(
        :vaccination,
        Person.Vaccination.changeset(
          Ecto.Changeset.get_field(changeset, :vaccination, %Person.Vaccination{}),
          %{}
        )
      )
      |> update_changeset_param(
        :jab_dates,
        &(&1 |> Kernel.||([]) |> Enum.concat([nil]))
      )

    params = update_changeset_param(changeset, :vaccination, fn _input -> vaccination_params end)

    {:noreply,
     assign(socket, :changeset, %Ecto.Changeset{
       CaseContext.change_person(person, params, %{vaccination_required: true, clean_nil_jab_dates: true})
       | action: :validate
     })}
  end

  def handle_event(
        "remove_vaccination_jab_date",
        %{"index" => index} = _params,
        %{assigns: %{changeset: changeset, person: person}} = socket
      ) do
    index = String.to_integer(index)

    vaccination_params =
      changeset
      |> Ecto.Changeset.get_change(
        :vaccination,
        Person.Vaccination.changeset(
          Ecto.Changeset.get_field(changeset, :vaccination, %Person.Vaccination{}),
          %{}
        )
      )
      |> update_changeset_param(:jab_dates, &List.delete_at(&1, index))

    params = update_changeset_param(changeset, :vaccination, fn _input -> vaccination_params end)

    {:noreply,
     assign(socket, :changeset, %Ecto.Changeset{
       CaseContext.change_person(person, params, %{vaccination_required: true, clean_nil_jab_dates: true})
       | action: :validate
     })}
  end

  def handle_event("validate", %{"person" => person_params}, socket) do
    person_params =
      Map.update(person_params, "vaccination", %{"jab_dates" => []}, fn vaccination ->
        case vaccination["done"] do
          "true" ->
            Map.update(
              vaccination,
              "jab_dates",
              [nil, nil],
              &Enum.map(&1, fn
                "" -> nil
                other -> other
              end)
            )

          _else ->
            %{"done" => "false", "jab_dates" => []}
        end
      end)

    {:noreply,
     assign(socket, :changeset, %Ecto.Changeset{
       CaseContext.change_person(socket.assigns.person, person_params, %{
         vaccination_required: true,
         clean_nil_jab_dates: true
       })
       | action: :validate
     })}
  end

  @impl Phoenix.LiveView
  def handle_event("advance", _params, socket) do
    vaccination_params =
      socket.assigns.changeset
      |> Ecto.Changeset.get_change(
        :vaccination,
        Person.Vaccination.changeset(
          Ecto.Changeset.get_field(socket.assigns.changeset, :vaccination, %Person.Vaccination{}),
          %{}
        )
      )
      |> update_changeset_param(
        :jab_dates,
        &(&1
          |> Kernel.||([])
          |> Enum.reject(fn date -> is_nil(date) end)
          |> Enum.uniq()
          |> Enum.sort_by(
            fn
              date when is_binary(date) -> Date.from_iso8601!(date)
              date -> date
            end,
            {:asc, Date}
          ))
      )

    params =
      update_changeset_param(socket.assigns.changeset, :vaccination, fn _input ->
        vaccination_params
      end)

    {:ok, person} =
      CaseContext.update_person(
        %Ecto.Changeset{socket.assigns.changeset | action: nil},
        params,
        %{vaccination_required: true, clean_nil_jab_dates: false}
      )

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
