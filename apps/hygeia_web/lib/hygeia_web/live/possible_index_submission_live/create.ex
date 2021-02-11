defmodule HygeiaWeb.PossibleIndexSubmissionLive.Create do
  @moduledoc false

  use HygeiaWeb, :surface_view

  alias Hygeia.CaseContext
  alias Hygeia.CaseContext.PossibleIndexSubmission
  alias HygeiaWeb.PolyfilledDateInput, as: DateInput
  alias Surface.Components.Form
  alias Surface.Components.Form.EmailInput
  alias Surface.Components.Form.ErrorTag
  alias Surface.Components.Form.Field
  alias Surface.Components.Form.HiddenInput
  alias Surface.Components.Form.Input.InputContext
  alias Surface.Components.Form.Inputs

  alias Surface.Components.Form.Select
  alias Surface.Components.Form.TelephoneInput
  alias Surface.Components.Form.TextArea
  alias Surface.Components.Form.TextInput

  data step, :atom, default: :base

  @impl Phoenix.LiveView
  def mount(%{"case_uuid" => case_uuid} = params, _session, socket) do
    case = CaseContext.get_case!(case_uuid)

    socket =
      if authorized?(PossibleIndexSubmission, :create, get_auth(socket), %{case: case}) do
        assign(socket,
          case: case,
          changeset:
            case
            |> Ecto.build_assoc(:possible_index_submissions)
            |> CaseContext.change_possible_index_submission(params)
        )
      else
        socket
        |> push_redirect(to: Routes.home_path(socket, :index))
        |> put_flash(:error, gettext("You are not authorized to do this action."))
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

  def handle_event("goto_step", %{"active" => "1", "step" => step}, socket),
    do: {:noreply, assign(socket, step: String.to_existing_atom(step))}

  def handle_event("goto_step", _params, socket), do: {:noreply, socket}

  def handle_event(
        "save",
        %{"possible_index_submission" => possible_index_submission_params},
        socket
      ) do
    socket.assigns.case
    |> CaseContext.create_possible_index_submission(possible_index_submission_params)
    |> case do
      {:ok, _possible_index_submission} ->
        {:noreply,
         socket
         |> put_flash(:info, gettext("Possible index submission created successfully"))
         |> push_redirect(
           to: Routes.possible_index_submission_index_path(socket, :index, socket.assigns.case)
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
      |> Ecto.Changeset.get_change(relation_or_embed)
      |> has_error?(path_tail)
  end

  defp steps(current_step) do
    steps = [
      base: gettext("Person Base Data"),
      transmission_date: gettext("Transmission Date"),
      infection_place: gettext("Infection Place"),
      infection_place_address: gettext("Meet Address"),
      infection_place_activity_mapping: gettext("Activity Mapping"),
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
