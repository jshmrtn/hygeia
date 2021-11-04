defmodule HygeiaWeb.TenantLive.Create do
  @moduledoc false

  use HygeiaWeb, :surface_view

  alias Hygeia.TenantContext
  alias Hygeia.TenantContext.Tenant
  alias Surface.Components.Form
  alias Surface.Components.Form.ErrorTag
  alias Surface.Components.Form.Field

  alias Surface.Components.Form.TextInput

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    socket =
      if authorized?(Tenant, :create, get_auth(socket)) do
        assign(socket, changeset: TenantContext.change_tenant(%Tenant{}))
      else
        socket
        |> push_redirect(to: Routes.home_index_path(socket, :index))
        |> put_flash(:error, gettext("You are not authorized to do this action."))
      end

    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def handle_event("validate", %{"tenant" => tenant_params}, socket) do
    {:noreply,
     assign(socket, :changeset, %{
       TenantContext.change_tenant(%Tenant{}, tenant_params)
       | action: :validate
     })}
  end

  def handle_event("save", %{"tenant" => tenant_params}, socket) do
    tenant_params
    |> TenantContext.create_tenant()
    |> case do
      {:ok, tenant} ->
        {:noreply,
         socket
         |> put_flash(:info, gettext("Tenant created successfully"))
         |> push_redirect(to: Routes.tenant_show_path(socket, :show, tenant))}

      {:error, changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end
end
