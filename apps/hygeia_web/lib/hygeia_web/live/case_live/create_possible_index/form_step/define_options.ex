defmodule HygeiaWeb.CaseLive.CreatePossibleIndex.FormStep.DefineOptions do
  @moduledoc false

  use HygeiaWeb, :surface_live_component

  import Ecto.Changeset
  import HygeiaGettext

  alias Phoenix.LiveView.Socket

  alias Hygeia.CaseContext
  alias Hygeia.CaseContext.Case
  alias Hygeia.CaseContext.Case.Status
  alias Hygeia.CaseContext.Person
  alias HygeiaWeb.CaseLive.CreatePossibleIndex.CaseSnippet
  alias HygeiaWeb.CaseLive.CreatePossibleIndex.PersonCard

  alias Surface.Components.Form
  alias Surface.Components.Form.ErrorTag
  alias Surface.Components.Form.Field
  alias Surface.Components.Form.HiddenInput
  alias Surface.Components.Form.Select
  alias Surface.Components.Link

  prop form_step, :string, required: true
  prop live_action, :atom, required: true
  prop current_form_data, :map, required: true
  prop supervisor_users, :map, required: true
  prop tracer_users, :map, required: true

  data bindings, :list, default: []

  @impl Phoenix.LiveComponent
  def update(%{current_form_data: current_form_data} = assigns, socket) do
    updated_data =
      update_step_data(current_form_data, %{
        type: current_form_data[:type],
        date: current_form_data[:date],
        type_other: current_form_data[:type_other],
        propagator: current_form_data[:propagator]
      })

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:bindings, Map.get(updated_data, :bindings, []))}
  end

  @impl Phoenix.LiveComponent
  def handle_event(
        "validate",
        %{"index" => index, "case" => case_params},
        %Socket{assigns: %{bindings: bindings}} = socket
      ) do
    bindings =
      List.update_at(
        bindings,
        String.to_integer(index),
        fn %{case_changeset: case_changeset} = binding ->
          Map.put(
            binding,
            :case_changeset,
            validation_changeset(case_changeset, Case, normalize_params(case_params))
          )
        end
      )

    send(self(), {:feed, %{bindings: bindings}})

    {:noreply, assign(socket, bindings: bindings)}
  end

  @impl Phoenix.LiveComponent
  def handle_event("next", _params, %Socket{assigns: %{bindings: bindings}} = socket) do
    case valid?(bindings) do
      true ->
        send(self(), {:proceed, %{bindings: bindings}})
        {:noreply, socket}

      false ->
        {:noreply, socket}
    end
  end

  def handle_event("back", _params, %Socket{assigns: %{bindings: bindings}} = socket) do
    send(self(), {:return, %{bindings: bindings}})
    {:noreply, socket}
  end

  @spec form_options_administrators(
          tenant_mapping :: %{String.t() => Person.t()},
          target_tenant_uuid :: String.t()
        ) ::
          list()
  def form_options_administrators(tenant_mapping, target_tenant_uuid) do
    tenant_mapping
    |> Enum.find_value(
      [],
      fn {tenant_uuid, assignees} ->
        if tenant_uuid == target_tenant_uuid,
          do: assignees
      end
    )
    |> Enum.map(&{&1.display_name, &1.uuid})
  end

  @spec update_step_data(form_data :: map(), changed_data :: map()) :: map()
  def update_step_data(form_data, changed_data)

  def update_step_data(%{bindings: bindings} = form_data, changed_data) do
    Map.put(
      form_data,
      :bindings,
      Enum.map(bindings, fn %{case_changeset: case_changeset} = binding ->
        case_changeset =
          case_changeset
          |> IO.inspect(label: "BEFORE MERGE PHASES")
          |> merge_phases(changed_data)
          |> IO.inspect(label: "AFTER MERGE PHASES")
          |> merge_propagator_administrators(changed_data)

        Map.put(binding, :case_changeset, case_changeset)
      end)
    )
  end

  def update_step_data(form_data, _data), do: form_data

  defp manage_statuses(transmission_type, statuses)
  defp manage_statuses(:travel, statuses), do: statuses
  defp manage_statuses(:contact_person, statuses), do: statuses

  defp manage_statuses(_transmission_type, statuses) do
    Enum.map(statuses, fn
      {name, :done} -> [key: name, value: :done, disabled: true]
      {name, :canceled} -> [key: name, value: :canceled, disabled: true]
      {name, code} -> [key: name, value: code]
    end)
  end

  defp merge_propagator_administrators(case_changeset, data)

  defp merge_propagator_administrators(case_changeset, %{
         propagator: {_propagator, propagator_case}
       }) do
    CaseContext.change_case(case_changeset, %{
      supervisor_uuid: Map.fetch!(propagator_case, :supervisor_uuid),
      tracer_uuid: Map.fetch!(propagator_case, :tracer_uuid)
    })
  end

  defp merge_propagator_administrators(case_changeset, _data), do: case_changeset

  defp merge_phases(case_changeset, data) do
    existing_phases = fetch_field!(case_changeset, :phases)

    IO.inspect(fetch_change(case_changeset, :phases), label: "DSDK")

    existing_phases
    |> IO.inspect(label: "EXISTING PHASES")
    |> Enum.find(
      &(match?(%Case.Phase{details: %Case.Phase.Index{}}, &1) or
          match?(%Ecto.Changeset{action: :insert}, &1))
    )
    |> case do
      nil -> manage_existing_phases(case_changeset, existing_phases, data)
      _index_phase -> case_changeset
    end
  end

  defp manage_existing_phases(
         case_changeset,
         existing_phases,
         %{type: global_type, date: date} = data
       ) do
    global_type_other = data[:type_other]

    existing_phases
    |> Enum.find(&match?(%Case.Phase{details: %Case.Phase.PossibleIndex{type: ^global_type}}, &1))
    |> case do
      nil ->
        if global_type in [:contact_person, :travel] do
          {start_date, end_date} = phase_dates(Date.from_iso8601!(date))

          status_changed_phases =
            Enum.map(existing_phases, fn
              %Case.Phase{quarantine_order: true, start: old_phase_start} = phase ->
                if Date.compare(old_phase_start, start_date) == :lt do
                  %Case.Phase{
                    phase
                    | end: start_date,
                      send_automated_close_email: false
                  }
                else
                  %Case.Phase{phase | quarantine_order: false}
                end

              %Case.Phase{quarantine_order: quarantine_order} = phase
              when quarantine_order in [false, nil] ->
                phase
            end)

          Ecto.Changeset.put_embed(
            case_changeset,
            :phases,
            status_changed_phases ++
              [
                %Case.Phase{
                  details: %Case.Phase.PossibleIndex{
                    type: global_type,
                    type_other: global_type_other
                  },
                  quarantine_order: true,
                  order_date: DateTime.utc_now(),
                  start: start_date,
                  end: end_date
                }
              ]
          )
        else
          Ecto.Changeset.put_embed(
            case_changeset,
            :phases,
            existing_phases ++
              [
                %Case.Phase{
                  details: %Case.Phase.PossibleIndex{
                    type: global_type,
                    type_other: global_type_other
                  }
                }
              ]
          )
        end

      %Case.Phase{} ->
        case_changeset
    end
  end

  defp manage_existing_phases(case_changeset, _existing_phases, _data),
    do: case_changeset

  @spec phase_dates(Date.t()) :: {Date.t(), Date.t()}
  def phase_dates(contact_date) do
    start_date = contact_date
    end_date = Date.add(start_date, 9)

    start_date =
      if Date.compare(start_date, Date.utc_today()) == :lt do
        Date.utc_today()
      else
        start_date
      end

    end_date =
      if Date.compare(end_date, Date.utc_today()) == :lt do
        Date.utc_today()
      else
        end_date
      end

    {start_date, end_date}
  end

  defp normalize_params(params) do
    Map.new(params, fn
      {k, ""} -> {String.to_existing_atom(k), nil}
      {k, v} -> {String.to_existing_atom(k), v}
    end)
  end

  @spec valid?(bindings :: list()) :: boolean()
  def valid?(bindings)

  def valid?(nil), do: false

  def valid?(bindings) do
    Enum.reduce(bindings, length(bindings) > 0, fn %{case_changeset: case_changeset}, truth ->
      case_changeset.valid? and truth
    end)
  end
end
