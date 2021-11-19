defmodule HygeiaWeb.CaseLive.CreatePossibleIndex.FormStep.DefineAdministration do
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
  alias HygeiaWeb.CaseLive.CreatePossibleIndex.Service

  alias Surface.Components.Form
  alias Surface.Components.Form.ErrorTag
  alias Surface.Components.Form.Field
  alias Surface.Components.Form.HiddenInput
  alias Surface.Components.Form.Select
  alias Surface.Components.Link

  prop form_step, :string, required: true
  prop live_action, :atom, required: true
  prop form_data, :map, required: true
  prop supervisor_users, :map, required: true
  prop tracer_users, :map, required: true

  @impl Phoenix.LiveComponent
  def handle_event(
        "validate",
        %{"index" => index, "case" => case_params},
        %Socket{assigns: %{form_data: form_data}} = socket
      ) do
    bindings =
      List.update_at(
        form_data.bindings,
        String.to_integer(index),
        fn %{case_changeset: case_changeset} = binding ->
          Map.put(
            binding,
            :case_changeset,
            CaseContext.change_case(case_changeset, case_params)
          )
        end
      )

    send(self(), {:feed, %{bindings: bindings}})

    {:noreply, socket}
  end

  @impl Phoenix.LiveComponent
  def handle_event("next", _params, socket) do
    send(self(), :proceed)
    {:noreply, socket}
  end

  def handle_event("back", _params, socket) do
    send(self(), :return)
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
        if match?(^tenant_uuid, target_tenant_uuid),
          do: assignees
      end
    )
    |> Enum.map(&{&1.display_name, &1.uuid})
  end

  @spec update_step_data(form_data :: map()) :: map()
  def update_step_data(form_data)

  def update_step_data(%{bindings: bindings} = form_data) do
    Map.put(
      form_data,
      :bindings,
      Enum.map(bindings, fn %{case_changeset: case_changeset} = binding ->
        case_changeset =
          case_changeset
          |> merge_phases(%{
            type: form_data[:type],
            type_other: form_data[:type_other],
            date: form_data[:date]
          })
          |> merge_propagator_administrators(form_data[:propagator_case])

        Map.put(binding, :case_changeset, case_changeset)
      end)
    )
  end

  def update_step_data(form_data), do: form_data

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

  defp merge_propagator_administrators(case_changeset, nil), do: case_changeset

  defp merge_propagator_administrators(case_changeset, propagator_case) do
    CaseContext.change_case(case_changeset, %{
      supervisor_uuid:
        get_change(case_changeset, :supervisor_uuid) || propagator_case.supervisor_uuid,
      tracer_uuid: get_change(case_changeset, :tracer_uuid) || propagator_case.tracer_uuid
    })
  end

  defp merge_phases(case_changeset, data) do
    existing_phases = case_changeset.data.phases

    if has_index_phase?(existing_phases) do
      case_changeset
    else
      manage_existing_phases(case_changeset, existing_phases, data)
    end
  end

  defp has_index_phase?(phases) do
    phases
    |> Enum.find(&match?(%Case.Phase{details: %Case.Phase.Index{}}, &1))
    |> case do
      nil -> false
      _phase -> true
    end
  end

  defp manage_existing_phases(
         case_changeset,
         existing_phases,
         %{type: global_type, type_other: global_type_other, date: date}
       ) do
    existing_phases
    |> Enum.find(&match?(%Case.Phase{details: %Case.Phase.PossibleIndex{type: ^global_type}}, &1))
    |> case do
      nil ->
        changeset = case_changeset |> Map.put(:errors, []) |> Map.put(:valid?, true)

        case_changeset =
          if global_type in [:contact_person, :travel] do
            {start_date, end_date} = Service.phase_dates(Date.from_iso8601!(date))

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

            put_embed(
              changeset,
              :phases,
              status_changed_phases ++
                [
                  %Case.Phase{
                    details: %Case.Phase.PossibleIndex{
                      type: global_type,
                      type_other: nil
                    },
                    quarantine_order: true,
                    order_date: DateTime.utc_now(),
                    start: start_date,
                    end: end_date
                  }
                ]
            )
          else
            put_embed(
              changeset,
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

        CaseContext.change_case(case_changeset)

      %Case.Phase{} ->
        case_changeset
    end
  end

  @spec valid?(form_data :: map()) :: boolean()
  def valid?(form_data)

  def valid?(%{bindings: bindings}) do
    Enum.reduce(bindings, length(bindings) > 0, fn %{case_changeset: case_changeset}, truth ->
      case_changeset.valid? and truth
    end)
  end

  def valid?(_form_data), do: false
end
