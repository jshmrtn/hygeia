defmodule HygeiaWeb.CaseLive.CreatePossibleIndex.FormStep.DefineOptions do
  @moduledoc false

  use HygeiaWeb, :surface_live_component
  use Ecto.Schema

  import Ecto.Changeset
  import HygeiaGettext

  alias Hygeia.CaseContext.Case.Status
  alias HygeiaWeb.CaseLive.CreatePossibleIndex.PersonCard

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
    {:ok,
     socket
     |> assign(assigns)
     |> assign(:bindings, assigns.current_form_data |> Map.get(:bindings, []))}
  end

  @impl Phoenix.LiveComponent
  def handle_event("validate", %{"binding_uuid" => binding_uuid, "case" => case_params}, socket) do
    %{assigns: %{bindings: bindings}} = socket

    normalized_params =
      case_params
      |> Map.new(fn {k, v} -> {String.to_atom(k), v} end)

    bindings =
      bindings
      |> Enum.map(fn
          %{uuid: uuid, case_changeset: case_changeset} = binding when uuid == binding_uuid ->
            Map.put(binding, :case_changeset, case_changeset |> change(normalized_params))
          binding -> binding
      end)

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

  defp valid?(bindings) do
    Enum.reduce(bindings, length(bindings) > 0, fn (%{case_changeset: case_changeset}, truth) ->
      case_changeset.valid? and truth
    end)
  end
end
