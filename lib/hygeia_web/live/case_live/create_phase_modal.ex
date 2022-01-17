defmodule HygeiaWeb.CaseLive.CreatePhaseModal do
  @moduledoc false

  use HygeiaWeb, :surface_live_component

  import Ecto.Changeset

  alias Hygeia.CaseContext
  alias Hygeia.CaseContext.Case
  alias Hygeia.CaseContext.Case.Phase
  alias Hygeia.CaseContext.Case.Status
  alias HygeiaWeb.PolimorphicInputs
  alias Surface.Components.Form
  alias Surface.Components.Form.Checkbox
  alias Surface.Components.Form.DateInput
  alias Surface.Components.Form.ErrorTag
  alias Surface.Components.Form.Field
  alias Surface.Components.Form.RadioButton
  alias Surface.Components.Form.Select

  @typep additional_action ::
           {:status, Case.Status.t()}
           | {:phase_end_date, Phase.t(), Date.t()}
           | {:phase_end_reason, Phase.t(),
              Phase.Index.EndReason.t() | Phase.PossibleIndex.EndReason.t()}
           | {:phase_quarantine_order, Phase.t(), false}
           | {:phase_send_automated_close_email, Phase.t(), false}

  prop case, :map, required: true
  prop close, :event, required: true
  prop params, :map, default: %{}
  prop caller_id, :any, required: true
  prop caller_module, :atom, required: true

  @impl Phoenix.LiveComponent
  def update(assigns, socket) do
    params = assigns.params || socket.assigns.params

    changeset = Phase.changeset(%Phase{}, params)

    {:ok, socket |> assign(assigns) |> assign(changeset: changeset)}
  end

  @impl Phoenix.LiveComponent
  def handle_event("validate", %{"phase" => phase_params}, socket) do
    {:noreply,
     socket
     |> assign(
       changeset: %{
         (%Phase{}
          |> Phase.changeset(phase_params)
          |> validate_type_unique(socket.assigns.case))
         | action: :validate
       }
     )
     |> maybe_block_navigation()}
  end

  def handle_event(
        "save",
        %{"phase" => phase_params},
        socket
      ) do
    true = authorized?(socket.assigns.case, :update, get_auth(socket))

    socket.assigns.case
    |> CaseContext.update_case(
      %Phase{}
      |> Phase.changeset(phase_params)
      |> additional_actions(socket.assigns.case)
      |> Enum.reduce(
        socket.assigns.case
        |> CaseContext.change_case()
        |> changeset_add_to_params(:phases, phase_params),
        &execute_action/2
      )
    )
    |> handle_save_response(socket, phase_params)
  end

  defp validate_type_unique(changeset, case) do
    case get_field(changeset, :details) do
      nil ->
        changeset

      %Phase.Index{} ->
        if Enum.find(case.phases, &match?(%Phase{details: %Phase.Index{}}, &1)) do
          add_error(
            changeset,
            :type,
            gettext("Phase Type already exists on the case")
          )
        else
          changeset
        end

      %Phase.PossibleIndex{type: type} ->
        if Enum.find(case.phases, &match?(%Phase{details: %Phase.PossibleIndex{type: ^type}}, &1)) do
          add_error(
            changeset,
            :type,
            gettext("Phase Type already exists on the case")
          )
        else
          changeset
        end

      %Ecto.Changeset{} ->
        changeset
    end
  end

  defp handle_save_response({:ok, _case}, socket, _phase_params) do
    send_update(socket.assigns.caller_module,
      id: socket.assigns.caller_id,
      __close_phase_create_modal__: true
    )

    send(self(), {:put_flash, :info, gettext("Phase created successfully")})

    {
      :noreply,
      socket
    }
  end

  defp handle_save_response({:error, _changeset}, socket, phase_params),
    do:
      {:noreply,
       socket
       |> assign(
         changeset: %{
           (%Phase{}
            |> Phase.changeset(phase_params)
            |> validate_type_unique(socket.assigns.case))
           | action: :insert
         }
       )
       |> maybe_block_navigation()}

  @spec additional_actions(changeset :: Ecto.Changeset.t(Phase.t()), case :: Case.t()) :: [
          additional_action
        ]
  defp additional_actions(changeset, case)
  defp additional_actions(%Ecto.Changeset{valid?: false}, _case), do: []

  defp additional_actions(%Ecto.Changeset{valid?: true} = changeset, case) do
    List.flatten([
      additional_actions_status(changeset, case),
      additional_actions_phase_date(changeset, case),
      additional_actions_phase_end_reason(changeset, case),
      additional_actions_phase_quarantine_order(changeset, case),
      additional_actions_phase_automated_case_closed_email(changeset, case)
    ])
  end

  defp additional_actions_status(changeset, case) do
    cond do
      fetch_field!(changeset, :type) != :index -> []
      case.status == :first_contact -> []
      true -> [{:status, :first_contact}]
    end
  end

  defp additional_actions_phase_date(changeset, case) do
    if fetch_field!(changeset, :quarantine_order) do
      new_start_date = fetch_field!(changeset, :start)
      new_end_date = fetch_field!(changeset, :end)

      case.phases
      |> Enum.map(fn phase ->
        cond do
          Date.compare(phase.start, new_start_date) in [:lt, :eq] and
              Date.compare(new_end_date, phase.end) in [:lt, :eq] ->
            nil

          Date.compare(phase.start, new_end_date) == :lt and
              Date.compare(new_end_date, phase.end) == :lt ->
            {:phase_start_date, phase, new_end_date}

          Date.compare(phase.start, new_start_date) == :lt and
              Date.compare(new_start_date, phase.end) == :lt ->
            {:phase_end_date, phase, new_start_date}

          true ->
            nil
        end
      end)
      |> Enum.reject(&is_nil/1)
    else
      []
    end
  end

  defp additional_actions_phase_quarantine_order(changeset, case) do
    if fetch_field!(changeset, :quarantine_order) do
      new_start_date = fetch_field!(changeset, :start)
      new_end_date = fetch_field!(changeset, :end)

      case.phases
      |> Enum.map(fn phase ->
        cond do
          Date.compare(new_start_date, phase.start) in [:lt, :eq] and
              Date.compare(phase.end, new_end_date) in [:lt, :eq] ->
            {:phase_quarantine_order, :cover, phase, false}

          Date.compare(phase.start, new_start_date) in [:lt, :eq] and
              Date.compare(new_end_date, phase.end) in [:lt, :eq] ->
            {:phase_quarantine_order, :contain, phase, false}

          true ->
            nil
        end
      end)
      |> Enum.reject(&is_nil/1)
    else
      []
    end
  end

  defp additional_actions_phase_end_reason(changeset, case) do
    with :index <- fetch_field!(changeset, :type),
         [_ | _] = change_phases <-
           Enum.reject(
             case.phases,
             &match?(%Phase{details: %Phase.PossibleIndex{end_reason: :converted_to_index}}, &1)
           ) do
      Enum.map(change_phases, &{:phase_end_reason, &1, :converted_to_index})
    else
      :possible_index -> []
      [] -> []
    end
  end

  defp additional_actions_phase_automated_case_closed_email(changeset, case) do
    if fetch_field!(changeset, :quarantine_order) do
      new_end_date = fetch_field!(changeset, :end)

      case.phases
      |> Enum.sort_by(fn %Phase{end: end_date} -> end_date end, {:asc, Date})
      |> Enum.map(&{:phase_send_automated_close_email, &1, false})
      |> List.update_at(-1, fn
        {:phase_send_automated_close_email, phase, false} = action ->
          if Date.compare(phase.end, new_end_date) in [:lt, :eq] and
               fetch_field!(changeset, :send_automated_close_email) do
            action
          else
            {:phase_send_automated_close_email, phase, true}
          end
      end)
    else
      []
    end
  end

  @spec execute_action(action :: additional_action(), acc :: map) :: map
  defp execute_action(action, acc)
  defp execute_action({:status, new_status}, acc), do: Map.put(acc, "status", new_status)

  defp execute_action({:phase_start_date, %Phase{uuid: uuid}, new_start_date}, acc) do
    Map.update!(
      acc,
      "phases",
      &Enum.map(&1, fn
        %{"uuid" => ^uuid} = phase -> Map.put(phase, "start", new_start_date)
        %{} = phase -> phase
      end)
    )
  end

  defp execute_action({:phase_end_date, %Phase{uuid: uuid}, new_end_date}, acc) do
    Map.update!(
      acc,
      "phases",
      &Enum.map(&1, fn
        %{"uuid" => ^uuid} = phase -> Map.put(phase, "end", new_end_date)
        %{} = phase -> phase
      end)
    )
  end

  defp execute_action({:phase_end_reason, %Phase{uuid: uuid}, new_end_reason}, acc) do
    Map.update!(
      acc,
      "phases",
      &Enum.map(&1, fn
        %{"uuid" => ^uuid} = phase ->
          Map.update(phase, "details", %{"end_reason" => new_end_reason}, fn details ->
            Map.put(details, "end_reason", new_end_reason)
          end)

        %{} = phase ->
          phase
      end)
    )
  end

  defp execute_action({:phase_quarantine_order, _type, %Phase{uuid: uuid}, false}, acc) do
    Map.update!(
      acc,
      "phases",
      &Enum.map(&1, fn
        %{"uuid" => ^uuid} = phase -> Map.put(phase, "quarantine_order", false)
        %{} = phase -> phase
      end)
    )
  end

  defp execute_action({:phase_send_automated_close_email, %Phase{uuid: uuid}, truth}, acc) do
    Map.update!(
      acc,
      "phases",
      &Enum.map(&1, fn
        %{"uuid" => ^uuid} = phase -> Map.put(phase, "send_automated_close_email", truth)
        %{} = phase -> phase
      end)
    )
  end

  defp maybe_block_navigation(%{assigns: %{changeset: %{changes: changes}}} = socket) do
    if changes == %{} do
      push_event(socket, "unblock_navigation", %{})
    else
      push_event(socket, "block_navigation", %{})
    end
  end
end
