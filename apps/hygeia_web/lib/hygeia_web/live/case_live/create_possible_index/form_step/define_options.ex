defmodule HygeiaWeb.CaseLive.CreatePossibleIndex.FormStep.DefineOptions do
  @moduledoc false

  use HygeiaWeb, :surface_live_component

  import Ecto.Changeset
  import HygeiaGettext

  alias Hygeia.CaseContext.Case
  alias Hygeia.CaseContext.Case.Status
  alias HygeiaWeb.CaseLive.CreatePossibleIndex.PersonCard
  alias HygeiaWeb.CaseLive.CreatePossibleIndex.CaseSnippet

  alias Surface.Components.Form
  alias Surface.Components.Form.ErrorTag
  alias Surface.Components.Form.HiddenInput
  alias Surface.Components.Form.Field
  alias Surface.Components.Form.Select
  alias Surface.Components.Link

  prop form_step, :string, required: true
  prop live_action, :atom, required: true
  prop current_form_data, :map, required: true
  prop supervisor_users, :map, required: true
  prop tracer_users, :map, required: true

  @impl Phoenix.LiveComponent
  def mount(socket) do
    {:ok,
     assign(socket,
       bindings: [],
       loading: false
     )}
  end

  @impl Phoenix.LiveComponent
  def update(assigns, socket) do
    %{current_form_data: data, supervisor_users: supervisor_users, tracer_users: tracer_users} = assigns

    bindings =
      data[:bindings]
      |> copy_propagator_data(data[:propagator], supervisor_users, tracer_users)
      |> validate_statuses(data[:type])

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:bindings, bindings)}
  end

  @impl Phoenix.LiveComponent
  def handle_event("validate", %{"index" => index, "case" => case_params}, socket) do
    %{assigns: %{bindings: bindings, current_form_data: data}} = socket

    bindings =
      List.update_at(
        bindings,
        String.to_integer(index),
        fn %{case_changeset: case_changeset} = binding ->
          Map.put(
            binding,
            :case_changeset,
            change(case_changeset, normalize_params(case_params))
          )
          |> validate_status(data[:type])
        end
      )

    {:noreply,
     socket
     |> assign(:bindings, bindings)}
  end

  @impl Phoenix.LiveComponent
  def handle_event("next", _, socket) do
    %{assigns: %{bindings: bindings}} = socket

    case valid?(bindings) do
      true ->
        send(self(), {:proceed, %{bindings: bindings}})
        {:noreply, socket}

      false ->
        {:noreply, socket}
    end
  end

  def handle_event("back", _, socket) do
    %{assigns: %{bindings: bindings}} = socket

    send(self(), {:return, %{bindings: bindings}})
    {:noreply, socket}
  end

  def assignees_form_options(tenant_mappings, target_tenant_uuid) do
    tenant_mappings
    |> Enum.find_value(
      [],
      fn {tenant_uuid, assignees} ->
        if tenant_uuid == target_tenant_uuid,
          do: assignees
      end
    )
    |> Enum.map(&{&1.display_name, &1.uuid})
  end

  defp manage_statuses(transmission_type, statuses)
  defp manage_statuses(:travel, statuses), do: statuses
  defp manage_statuses(:contact_person, statuses), do: statuses

  defp manage_statuses(_, statuses) do
    Enum.map(statuses, fn
      {name, :done} -> [key: name, value: :done, disabled: true]
      {name, :canceled} -> [key: name, value: :canceled, disabled: true]
      {name, code} -> [key: name, value: code]
    end)
  end

  defp copy_propagator_data(bindings, propagator, supervisor_users, tracer_users) do
    case propagator do
      nil -> bindings

      {_propagator, propagator_case} ->
        bindings
        |> Enum.map(fn %{case_changeset: case_changeset} = binding ->
          tenant_uuid = fetch_field!(case_changeset, :tenant_uuid)

          Map.put(
            binding,
            :case_changeset,
            change(case_changeset, %{
              supervisor_uuid:
                validate_assignee(
                  supervisor_users,
                  tenant_uuid,
                  propagator_case.supervisor_uuid
                ),
              tracer_uuid:
                validate_assignee(tracer_users, tenant_uuid, propagator_case.tracer_uuid)
            })
          )
        end)
    end
  end

  defp validate_statuses(bindings, type) when is_list(bindings) do
    Enum.map(bindings, &( validate_status(&1, type) ))
  end

  defp validate_status(binding, :travel), do: binding
  defp validate_status(binding, :contact_person), do: binding

  defp validate_status(binding, type) do
    %{case_changeset: case_changeset} = binding

    case not existing_entity?(case_changeset) and fetch_field!(case_changeset, :status) in [:done, :canceled] do
      true -> Map.put(binding, :case_changeset, add_error(case_changeset, :status, gettext("invalid status")) |> Map.put(:action, :validate))
      false -> Map.put(binding, :case_changeset, Map.merge(case_changeset, %{action: nil, errors: [], valid?: true}))
    end
  end

  defp choose_case_status(type) when type in [:contact_person, :travel], do: :done

  defp choose_case_status(_), do: :first_contact

  defp validate_assignee(tenant_mappings, target_tenant_uuid, assignee_uuid) do
    tenant_mappings
    |> Enum.find_value(
      [],
      fn {tenant_uuid, assignees} ->
        if tenant_uuid == target_tenant_uuid,
          do: assignees
      end
    )
    |> Enum.find_value(&if match?(&1, assignee_uuid), do: &1.uuid)
  end

  defp normalize_params(params) do
    params
    |> Map.new(fn
      {k, ""} -> {String.to_atom(k), nil}
      {k, v} -> {String.to_atom(k), v}
    end)
  end

  def valid?(nil), do: false
  def valid?(bindings) do
    Enum.reduce(bindings, length(bindings) > 0, fn %{case_changeset: case_changeset}, truth ->
      case_changeset.valid? and truth
    end)
  end
end
