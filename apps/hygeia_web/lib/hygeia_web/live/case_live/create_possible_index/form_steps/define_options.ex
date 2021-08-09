defmodule HygeiaWeb.CaseLive.CreatePossibleIndex.FormSteps.DefineOptions do
  @moduledoc false

  use HygeiaWeb, :surface_live_component
  use Ecto.Schema

  import Ecto.Changeset
  import HygeiaGettext

  alias Hygeia.CaseContext
  alias Hygeia.CaseContext.Case

  alias HygeiaWeb.CaseLive.CreatePossibleIndex.Service
  alias HygeiaWeb.CaseLive.CreatePossibleIndex.PersonCard
  alias HygeiaWeb.CaseLive.CreatePossibleIndex.FormSteps.DefinePeople

  alias Surface.Components.Form
  alias Surface.Components.Form.ErrorTag
  alias Surface.Components.Form.Field
  alias Surface.Components.Form.Select
  alias Surface.Components.Form.Input.InputContext
  alias Surface.Components.Form.Inputs

  prop form_step, :string, required: true
  prop live_action, :atom, required: true
  prop current_form_data, :keyword, required: true
  prop supervisor_users, :map, required: true
  prop tracer_users, :map, required: true

  @impl Phoenix.LiveComponent
  def mount(socket) do
    {:ok,
     assign(socket,
       changeset: DefinePeople.changeset(%DefinePeople{}),
       loading: false
     )}
  end

  @impl Phoenix.LiveComponent
  def update(assigns, socket) do
    changeset =
      assigns.current_form_data
      |> Keyword.get(DefinePeople, %DefinePeople{})
      |> IO.inspect()
      |> DefinePeople.changeset()

    {:ok,
     socket
     |> assign(assigns)
     |> assign(changeset: changeset)}
  end

  @impl Phoenix.LiveComponent
  def handle_event("validate", %{"define_people" => %{"people" => params}}, socket) do
    %{assigns: %{changeset: changeset}} = socket

    people =
      changeset
      |> get_field(:people, [])
      |> Enum.with_index()
      |> Enum.map(fn {person, index} ->
        put_assignees(person, case_params(params, "#{index}", "0"))
      end)

    changeset = %{
      DefinePeople.changeset(%DefinePeople{people: people})
      | action: :validate
    }

    {:noreply,
     socket
     |> assign(:changeset, changeset)}
  end

  @impl Phoenix.LiveComponent
  def handle_event("next", _, socket) do
    %{assigns: %{changeset: changeset}} = socket

    changeset
    |> apply_action(:validate)
    |> case do
      {:ok, struct} ->
        send(self(), {:proceed, {DefinePeople, struct}})
        {:noreply, socket}

      {:error, changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  def handle_event("back", _, socket) do
    %{assigns: %{changeset: changeset}} = socket

    changeset
    |> apply_changes
    |> then(&(
        send(self(), {:return, {DefinePeople, &1}})
    ))

    {:noreply, socket}
  end


  defp put_assignee(case, type, uuid)

  defp put_assignee(case, type, uuid),
    do: Map.put(case, type, uuid)

  defp put_assignees(person, case_params)
  defp put_assignees(person, nil), do: person

  defp put_assignees(person, case_params) do
    %{
      "status" => case_status,
      "supervisor_uuid" => supervisor_uuid,
      "tracer_uuid" => tracer_uuid
    } = case_params

    person
    |> Map.put(
      :cases,
      person
      |> Service.person_case()
      |> put_assignee(:status, case_status)
      |> put_assignee(:tracer_uuid, tracer_uuid)
      |> put_assignee(:supervisor_uuid, supervisor_uuid)
      |> List.wrap()
    )
  end

  defp case_params(people_params, person_index, case_index) do
    people_params
    |> Map.fetch(person_index)
    |> case do
      {:ok, params} ->
        params |> Map.get("cases") |> Map.get(case_index)

      :error ->
        nil
    end
  end

  def assignees_form_options(tenant_bindings, target_tenant_uuid) do
    tenant_bindings
    |> Enum.find_value(
      [],
      fn {tenant_uuid, assignees} ->
        if tenant_uuid == target_tenant_uuid,
          do: assignees
      end
    )
    |> Enum.map(&{&1.display_name, &1.uuid})
  end
end
