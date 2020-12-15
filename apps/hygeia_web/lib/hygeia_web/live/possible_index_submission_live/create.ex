defmodule HygeiaWeb.PossibleIndexSubmissionLive.Create do
  @moduledoc false

  use HygeiaWeb, :surface_view

  alias Hygeia.CaseContext
  alias Hygeia.CaseContext.PossibleIndexSubmission
  alias Surface.Components.Form
  alias Surface.Components.Form.DateInput
  alias Surface.Components.Form.EmailInput
  alias Surface.Components.Form.ErrorTag
  alias Surface.Components.Form.Field
  alias Surface.Components.Form.HiddenInput
  alias Surface.Components.Form.Input.InputContext
  alias Surface.Components.Form.Inputs
  alias Surface.Components.Form.Label
  alias Surface.Components.Form.Select
  alias Surface.Components.Form.TelephoneInput
  alias Surface.Components.Form.TextArea
  alias Surface.Components.Form.TextInput

  @steps [
    :base,
    :transmission_date,
    :infection_place,
    :infection_place_activity_mapping,
    :infection_place_address,
    :contact_methods,
    :address
  ]

  data step, :atom, default: :base

  @impl Phoenix.LiveView
  def mount(%{"case_uuid" => case_uuid} = params, session, socket) do
    case = CaseContext.get_case!(case_uuid)

    socket =
      if authorized?(PossibleIndexSubmission, :create, get_auth(socket), %{case: case}) do
        assign(socket,
          case: case,
          changeset:
            case
            |> Ecto.build_assoc(:possible_index_submissions)
            |> CaseContext.change_possible_index_submission(params),
          types: CaseContext.list_infection_place_types()
        )
      else
        socket
        |> push_redirect(to: Routes.home_path(socket, :index))
        |> put_flash(:error, gettext("You are not authorized to do this action."))
      end

    super(params, session, socket)
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
        "save",
        %{"possible_index_submission" => possible_index_submission_params},
        socket
      ) do
    socket.assigns.case
    |> CaseContext.create_possible_index_submission(possible_index_submission_params)
    |> case do
      {:ok, possible_index_submission} ->
        {:noreply,
         socket
         |> put_flash(:info, gettext("Possible index submission created successfully"))
         |> push_redirect(
           to:
             Routes.possible_index_submission_show_path(socket, :show, possible_index_submission)
         )}

      {:error, changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  def handle_event("advance", _params, socket) do
    index = step_index(socket.assigns.step)
    new_step = Enum.at(@steps, index + 1)

    {:noreply, assign(socket, step: new_step)}
  end

  defp step_index(step) do
    Enum.find_index(@steps, &(&1 == step))
  end

  defp errors_in?(changeset, paths) do
    paths
    |> Enum.map(fn
      field when is_atom(field) -> [field]
      tuple when is_tuple(tuple) -> Tuple.to_list(tuple)
    end)
    |> Enum.all?(&has_error?(changeset, &1))
  end

  defp has_error?(nil, _path), do: false
  defp has_error?(%Ecto.Changeset{errors: errors}, [field]), do: Keyword.has_key?(errors, field)

  defp has_error?(%Ecto.Changeset{errors: errors} = changeset, [relation_or_embed | path_tail]) do
    Keyword.has_key?(errors, relation_or_embed) ||
      changeset
      |> Ecto.Changeset.get_change(relation_or_embed)
      |> has_error?(path_tail)
  end
end
