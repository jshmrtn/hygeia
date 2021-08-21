defmodule HygeiaWeb.CaseLive.CreatePossibleIndex.FormStep.DefineOptions do
  @moduledoc """
    Form step responsible for managing case options.
  """

  use HygeiaWeb, :surface_live_component

  import Ecto.Changeset
  import HygeiaGettext

  alias Hygeia.CaseContext.Case.Person
  alias Hygeia.CaseContext.Case.Status
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
    %{current_form_data: data, supervisor_users: supervisor_users, tracer_users: tracer_users} =
      assigns

    bindings = Map.get(data, :bindings, [])
    propagator = assigns[:propagator]

    bindings =
      Enum.map(bindings, fn %{case_changeset: case_changeset} = binding ->
        case_changeset =
          merge_propagator_administrators(
            case_changeset,
            propagator,
            supervisor_users,
            tracer_users
          )

        Map.put(binding, :case_changeset, case_changeset)
      end)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(bindings: bindings)}
  end

  @impl Phoenix.LiveComponent
  def handle_event("validate", %{"index" => index, "case" => case_params}, socket) do
    %{assigns: %{bindings: bindings}} = socket

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
        end
      )

    {:noreply, assign(socket, bindings: bindings)}
  end

  @impl Phoenix.LiveComponent
  def handle_event("next", _params, socket) do
    %{assigns: %{bindings: bindings}} = socket

    case valid?(bindings) do
      true ->
        send(self(), {:proceed, %{bindings: bindings}})
        {:noreply, socket}

      false ->
        {:noreply, socket}
    end
  end

  def handle_event("back", _params, socket) do
    %{assigns: %{bindings: bindings}} = socket

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

  defp merge_propagator_administrators(case_changeset, propagator, supervisor_users, tracer_users)

  defp merge_propagator_administrators(case_changeset, nil, _sup_users, _trac_users),
    do: case_changeset

  defp merge_propagator_administrators(case_changeset, propagator, supervisor_users, tracer_users) do
    {_propagator, propagator_case} = propagator

    tenant_uuid = fetch_field!(case_changeset, :tenant_uuid)

    change(case_changeset, %{
      supervisor_uuid:
        validate_administrator(
          supervisor_users,
          tenant_uuid,
          propagator_case.supervisor_uuid
        ),
      tracer_uuid: validate_administrator(tracer_users, tenant_uuid, propagator_case.tracer_uuid)
    })
  end

  defp validate_administrator(tenant_mapping, target_tenant_uuid, administrator_uuid) do
    Enum.find_value(
      tenant_mapping,
      [],
      fn {tenant_uuid, admins} ->
        if tenant_uuid == target_tenant_uuid,
          do: Enum.find_value(admins, &if(match?(&1, administrator_uuid), do: &1.uuid))
      end
    )
  end

  defp normalize_params(params) do
    Map.new(params, fn
      {k, ""} -> {String.to_atom(k), nil}
      {k, v} -> {String.to_atom(k), v}
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
