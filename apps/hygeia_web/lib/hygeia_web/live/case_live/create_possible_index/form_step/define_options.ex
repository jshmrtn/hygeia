defmodule HygeiaWeb.CaseLive.CreatePossibleIndex.FormStep.DefineOptions do
  @moduledoc false

  use HygeiaWeb, :surface_live_component
  use Ecto.Schema

  import Ecto.Changeset
  import HygeiaGettext

  alias Hygeia.CaseContext.Case.Status
  alias HygeiaWeb.CaseLive.CreatePossibleIndex.PersonCard
  alias HygeiaWeb.CaseLive.CreatePossibleIndex.CaseSnippet

  alias Surface.Components.Form
  alias Surface.Components.Form.ErrorTag
  alias Surface.Components.Form.HiddenInput
  alias Surface.Components.Form.Field
  alias Surface.Components.Form.Select

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
    # TODO put in function
    bindings =
      case assigns.current_form_data[:propagator] do
        nil ->
          Map.get(assigns.current_form_data, :bindings, [])

        {_propagator, propagator_case} ->
          assigns.current_form_data
          |> Map.get(:bindings, [])
          |> Enum.map(fn %{case_changeset: case_changeset} = binding ->
            tenant_uuid = fetch_field!(case_changeset, :tenant_uuid)
            supervisor_users = Map.get(assigns, :supervisor_users, [])
            tracer_users = Map.get(assigns, :tracer_users, [])

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

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:bindings, bindings)}
  end

  @impl Phoenix.LiveComponent
  def handle_event("validate", %{"index" => index, "case" => case_params}, socket) do
    %{assigns: %{bindings: bindings}} = socket

    normalized_params =
      case_params
      |> Map.new(fn
        {k, ""} -> {String.to_atom(k), nil}
        {k, v} -> {String.to_atom(k), v}
      end)

    bindings =
      List.update_at(
        bindings,
        String.to_integer(index),
        fn %{case_changeset: case_changeset} = binding ->
          Map.put(
            binding,
            :case_changeset,
            change(case_changeset, normalized_params)
          )
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

  def valid?(nil), do: false
  def valid?(bindings) do
    Enum.reduce(bindings, length(bindings) > 0, fn %{case_changeset: case_changeset}, truth ->
      case_changeset.valid? and truth
    end)
  end
end
