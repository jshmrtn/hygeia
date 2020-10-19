defmodule HygeiaWeb.CaseLive.FormComponent do
  @moduledoc false

  use HygeiaWeb, :surface_live_component

  alias Hygeia.CaseContext
  alias Hygeia.CaseContext.Person
  alias Hygeia.TenantContext
  alias Hygeia.TenantContext.Tenant
  alias Hygeia.UserContext

  alias HygeiaWeb.FormError

  alias Surface.Components.Form
  alias Surface.Components.Form.DateInput
  alias Surface.Components.Form.Field
  alias Surface.Components.Form.Inputs
  alias Surface.Components.Form.Label
  alias Surface.Components.Form.Select

  prop case, :any, required: true
  prop action, :any, required: true
  prop return_to, :string, required: false, default: "#"

  @impl Phoenix.LiveComponent
  def update(%{case: case} = assigns, socket) do
    changeset = CaseContext.change_case(case)
    tenants = TenantContext.list_tenants()
    people = CaseContext.list_people()
    users = UserContext.list_users()

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:changeset, changeset)
     |> assign(:tenants, tenants)
     |> assign(:people, people)
     |> assign(:users, users)}
  end

  @impl Phoenix.LiveComponent
  def handle_event("validate", %{"case" => case_params}, socket) do
    changeset =
      socket.assigns.case
      |> CaseContext.change_case(case_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :changeset, changeset)}
  end

  def handle_event("save", %{"case" => case_params}, socket) do
    save_case(socket, socket.assigns.action, case_params)
  end

  defp save_case(socket, :edit, case_params) do
    case CaseContext.update_case(socket.assigns.case, case_params) do
      {:ok, _case} ->
        {:noreply,
         socket
         |> put_flash(:info, gettext("Case updated successfully"))
         |> push_redirect(to: socket.assigns.return_to)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  # credo:disable-for-next-line Credo.Check.Refactor.ABCSize
  defp save_case(
         %Phoenix.LiveView.Socket{assigns: %{tenants: tenants, people: people}} = socket,
         :new,
         %{"tenant_uuid" => tenant_uuid, "person_uuid" => person_uuid} = case_params
       ) do
    people
    |> Enum.find(&match?(%Person{uuid: ^person_uuid}, &1))
    |> CaseContext.create_case(
      Enum.find(tenants, &match?(%Tenant{uuid: ^tenant_uuid}, &1)),
      case_params
    )
    |> case do
      {:ok, _case} ->
        {:noreply,
         socket
         |> put_flash(:info, gettext("Case created successfully"))
         |> push_redirect(to: socket.assigns.return_to)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end
end
