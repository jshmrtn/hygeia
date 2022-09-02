defmodule HygeiaWeb.PossibleIndexSubmissionLive.Create do
  @moduledoc false

  use HygeiaWeb, :surface_view

  import Ecto.Changeset

  alias Phoenix.LiveView.Socket

  alias Hygeia.AutoTracingContext
  alias Hygeia.CaseContext
  alias Hygeia.CaseContext.Case
  alias Hygeia.CaseContext.PossibleIndexSubmission
  alias Hygeia.Repo
  alias HygeiaWeb.DateInput
  alias Surface.Components.Form
  alias Surface.Components.Form.EmailInput
  alias Surface.Components.Form.ErrorTag
  alias Surface.Components.Form.Field
  alias Surface.Components.Form.HiddenInput

  alias Surface.Components.Form.Inputs
  alias Surface.Components.Form.Select
  alias Surface.Components.Form.TelephoneInput
  alias Surface.Components.Form.TextArea
  alias Surface.Components.Form.TextInput

  data step, :atom, default: :base

  @impl Phoenix.LiveView
  def mount(%{"case_uuid" => case_uuid} = params, _session, socket) do
    case =
      case_uuid
      |> CaseContext.get_case!()
      |> Repo.preload(person: [], auto_tracing: [], tests: [])

    auth = get_auth(socket)

    socket =
      assign(socket,
        return_url: params["return_url"]
      )

    socket =
      cond do
        Case.closed?(case) and not authorized?(case, :details, auth) and
            authorized?(case, :partial_details, auth) ->
          raise HygeiaWeb.AutoTracingLive.AutoTracing.CaseClosedError, case_uuid: case.uuid

        !authorized?(PossibleIndexSubmission, :create, auth, %{case: case}) ->
          push_redirect(socket,
            to:
              Routes.auth_login_path(socket, :login,
                person_uuid: case.person_uuid,
                return_url: Routes.possible_index_submission_create_path(socket, :create, case)
              )
          )

        true ->
          assign(socket,
            case: case,
            person: case.person,
            changeset:
              case
              |> Ecto.build_assoc(:possible_index_submissions)
              |> CaseContext.change_possible_index_submission(params)
          )
      end

    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def handle_event(
        "validate",
        %{"possible_index_submission" => possible_index_submission_params},
        socket
      ) do
    {:noreply,
     assign(socket, :changeset, %{
       (socket.assigns.case
        |> Ecto.build_assoc(:possible_index_submissions)
        |> CaseContext.change_possible_index_submission(possible_index_submission_params))
       | action: :validate
     })}
  end

  def handle_event(
        "copy_household_address",
        _params,
        %Socket{assigns: %{changeset: changeset, person: person}} = socket
      ) do
    {:noreply, assign(socket, changeset: put_embed(changeset, :address, person.address))}
  end

  def handle_event(
        "copy_household_address_to_infection_place_address",
        _params,
        %Socket{assigns: %{changeset: changeset, person: person}} = socket
      ) do
    infection_place =
      changeset
      |> fetch_field!(:infection_place)
      |> Map.put(:address, person.address)

    {:noreply, assign(socket, changeset: put_embed(changeset, :infection_place, infection_place))}
  end

  def handle_event("goto_step", %{"active" => "1", "step" => step}, socket),
    do: {:noreply, assign(socket, step: String.to_existing_atom(step))}

  def handle_event("goto_step", _params, socket), do: {:noreply, socket}

  def handle_event(
        "save",
        %{"possible_index_submission" => possible_index_submission_params},
        socket
      ) do
    %CaseContext.Case{auto_tracing: auto_tracing} = socket.assigns.case

    if auto_tracing do
      {:ok, _} =
        AutoTracingContext.auto_tracing_add_problem(
          auto_tracing,
          :possible_index_submission
        )
    end

    socket.assigns.case
    |> CaseContext.create_possible_index_submission(possible_index_submission_params)
    |> case do
      {:ok, _possible_index_submission} ->
        {:noreply,
         socket
         |> put_flash(:info, gettext("Possible index submission created successfully"))
         |> push_redirect(
           to:
             socket.assigns.return_url ||
               Routes.possible_index_submission_index_path(socket, :index, socket.assigns.case)
         )}

      {:error, changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  def handle_event("advance", _params, socket) do
    new_step =
      socket.assigns.step
      |> steps()
      |> Enum.find_value(fn
        {step, {_name, false, false}} -> step
        _other -> false
      end)

    {:noreply, assign(socket, step: new_step)}
  end

  defp errors_in?(changeset, paths) do
    paths
    |> Enum.map(fn
      field when is_atom(field) -> [field]
      tuple when is_tuple(tuple) -> Tuple.to_list(tuple)
    end)
    |> Enum.any?(&has_error?(changeset, &1))
  end

  defp has_error?(nil, _path), do: false

  defp has_error?(%Ecto.Changeset{errors: errors}, [field]) do
    Keyword.has_key?(errors, field)
  end

  defp has_error?(%Ecto.Changeset{errors: errors} = changeset, [relation_or_embed | path_tail]) do
    Keyword.has_key?(errors, relation_or_embed) ||
      changeset
      |> get_change(relation_or_embed)
      |> has_error?(path_tail)
  end

  defp steps(current_step) do
    steps = [
      base: gettext("Person Base Data"),
      transmission_date: gettext("Transmission Date"),
      infection_place: gettext("Infection Place"),
      infection_place_address: gettext("Meet Address"),
      comment: gettext("Activity Mapping"),
      contact_methods: gettext("Contact Methods"),
      address: gettext("Address"),
      employer: gettext("Employer")
    ]

    current_index =
      steps
      |> Keyword.keys()
      |> Enum.find_index(&(&1 == current_step))

    steps
    |> Enum.with_index()
    |> Enum.map(fn {{step, name}, index} ->
      {step, {name, index == current_index, index < current_index}}
    end)
  end
end
