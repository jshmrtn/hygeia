defmodule HygeiaWeb.TenantLive.FormComponent do
  @moduledoc false

  use HygeiaWeb, :surface_live_component

  alias Hygeia.TenantContext
  alias HygeiaWeb.FormError
  alias Surface.Components.Form
  alias Surface.Components.Form.Field
  alias Surface.Components.Form.Label
  alias Surface.Components.Form.Select
  alias Surface.Components.Form.TextInput

  alias HygeiaWeb.PolimorphicInputs
  alias Surface.Components.Form.Input.InputContext

  @impl Phoenix.LiveComponent
  def update(%{tenant: tenant} = assigns, socket) do
    changeset = TenantContext.change_tenant(tenant)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:changeset, changeset)}
  end

  @impl Phoenix.LiveComponent
  def handle_event("validate", %{"tenant" => tenant_params}, socket) do
    changeset =
      socket.assigns.tenant
      |> TenantContext.change_tenant(tenant_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :changeset, changeset)}
  end

  def handle_event("save", %{"tenant" => tenant_params}, socket) do
    save_tenant(socket, socket.assigns.action, tenant_params)
  end

  defp save_tenant(socket, :edit, tenant_params) do
    case TenantContext.update_tenant(socket.assigns.tenant, tenant_params) do
      {:ok, _tenant} ->
        {:noreply,
         socket
         |> put_flash(:info, gettext("Tenant updated successfully"))
         |> push_redirect(to: socket.assigns.return_to)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  defp save_tenant(socket, :new, tenant_params) do
    case TenantContext.create_tenant(tenant_params) do
      {:ok, _tenant} ->
        {:noreply,
         socket
         |> put_flash(:info, gettext("Tenant created successfully"))
         |> push_redirect(to: socket.assigns.return_to)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end
end
