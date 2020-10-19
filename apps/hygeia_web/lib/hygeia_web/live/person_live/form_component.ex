defmodule HygeiaWeb.PersonLive.FormComponent do
  @moduledoc false

  use HygeiaWeb, :surface_live_component

  alias Hygeia.CaseContext
  alias Hygeia.TenantContext
  alias Hygeia.TenantContext.Tenant

  alias HygeiaWeb.FormError

  alias Surface.Components.Form
  alias Surface.Components.Form.DateInput
  alias Surface.Components.Form.Field
  alias Surface.Components.Form.Inputs
  alias Surface.Components.Form.Label
  alias Surface.Components.Form.Select
  alias Surface.Components.Form.TextInput

  prop person, :any, required: true
  prop action, :any, required: true
  prop return_to, :string, required: false, default: "#"

  @impl Phoenix.LiveComponent
  def update(%{person: person} = assigns, socket) do
    changeset = CaseContext.change_person(person)
    tenants = TenantContext.list_tenants()
    professions = CaseContext.list_professions()

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:changeset, changeset)
     |> assign(:tenants, tenants)
     |> assign(:professions, professions)}
  end

  @impl Phoenix.LiveComponent
  def handle_event("validate", %{"person" => person_params}, socket) do
    changeset =
      socket.assigns.person
      |> CaseContext.change_person(person_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :changeset, changeset)}
  end

  def handle_event("save", %{"person" => person_params}, socket) do
    save_person(socket, socket.assigns.action, person_params)
  end

  defp save_person(socket, :edit, person_params) do
    case CaseContext.update_person(socket.assigns.person, person_params) do
      {:ok, _person} ->
        {:noreply,
         socket
         |> put_flash(:info, gettext("Person updated successfully"))
         |> push_redirect(to: socket.assigns.return_to)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  defp save_person(
         %Phoenix.LiveView.Socket{assigns: %{tenants: tenants}} = socket,
         :new,
         %{"tenant_uuid" => tenant_uuid} = person_params
       ) do
    tenants
    |> Enum.find(&match?(%Tenant{uuid: ^tenant_uuid}, &1))
    |> CaseContext.create_person(person_params)
    |> case do
      {:ok, _person} ->
        {:noreply,
         socket
         |> put_flash(:info, gettext("Person created successfully"))
         |> push_redirect(to: socket.assigns.return_to)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end
end
