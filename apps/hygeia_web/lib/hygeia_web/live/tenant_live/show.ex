defmodule HygeiaWeb.TenantLive.Show do
  @moduledoc false

  use HygeiaWeb, :surface_view

  alias Hygeia.TenantContext
  alias Hygeia.TenantContext.Tenant
  alias Hygeia.TenantContext.Tenant.Smtp
  alias Hygeia.TenantContext.Tenant.Websms
  alias HygeiaWeb.PolimorphicInputs
  alias Surface.Components.Form
  alias Surface.Components.Form.Checkbox
  alias Surface.Components.Form.ErrorTag
  alias Surface.Components.Form.Field
  alias Surface.Components.Form.Input.InputContext
  alias Surface.Components.Form.Inputs
  alias Surface.Components.Form.PasswordInput
  alias Surface.Components.Form.Select
  alias Surface.Components.Form.TextArea
  alias Surface.Components.Form.TextInput
  alias Surface.Components.Link
  alias Surface.Components.LivePatch

  @impl Phoenix.LiveView
  def handle_params(%{"id" => id} = params, uri, socket) do
    tenant = TenantContext.get_tenant!(id)

    socket =
      if authorized?(
           tenant,
           case socket.assigns.live_action do
             :edit -> :update
             :show -> :details
           end,
           get_auth(socket)
         ) do
        Phoenix.PubSub.subscribe(Hygeia.PubSub, "tenants:#{id}")

        load_data(socket, tenant)
      else
        socket
        |> push_redirect(to: Routes.home_path(socket, :index))
        |> put_flash(:error, gettext("You are not authorized to do this action."))
      end

    super(params, uri, socket)
  end

  @impl Phoenix.LiveView
  def handle_info({:updated, %Tenant{} = tenant, _version}, socket) do
    {:noreply, assign(socket, :tenant, tenant)}
  end

  @impl Phoenix.LiveView
  def handle_info({:deleted, %Tenant{}, _version}, socket) do
    {:noreply, redirect(socket, to: Routes.tenant_index_path(socket, :index))}
  end

  def handle_info(_other, socket), do: {:noreply, socket}

  @impl Phoenix.LiveView
  def handle_event("reset", _params, socket) do
    tenant = TenantContext.get_tenant!(socket.assigns.tenant.uuid)

    {:noreply,
     socket
     |> load_data(tenant)
     |> push_patch(to: Routes.tenant_show_path(socket, :show, tenant))
     |> maybe_block_navigation()}
  end

  def handle_event("validate", %{"tenant" => tenant_params}, socket) do
    {:noreply,
     socket
     |> assign(
       changeset: %{
         TenantContext.change_tenant(socket.assigns.tenant, tenant_params)
         | action: :validate
       }
     )
     |> maybe_block_navigation()}
  end

  def handle_event("delete", _params, socket) do
    true = authorized?(socket.assigns.tenant, :delete, get_auth(socket))

    socket.assigns.tenant
    |> TenantContext.delete_tenant()
    |> case do
      {:ok, _tenant} ->
        {:noreply,
         socket
         |> put_flash(:info, gettext("Tenant deleted successfully"))
         |> redirect(to: Routes.organisation_index_path(socket, :index))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, changeset_error_flash(socket, changeset)}
    end
  end

  def handle_event("save", %{"tenant" => tenant_params}, socket) do
    true = authorized?(socket.assigns.tenant, :update, get_auth(socket))

    socket.assigns.tenant
    |> TenantContext.update_tenant(tenant_params)
    |> case do
      {:ok, tenant} ->
        {:noreply,
         socket
         |> load_data(tenant)
         |> put_flash(:info, gettext("Tenant updated successfully"))
         |> push_patch(to: Routes.tenant_show_path(socket, :show, tenant))}

      {:error, changeset} ->
        {:noreply,
         socket
         |> assign(changeset: changeset)
         |> maybe_block_navigation()}
    end
  end

  defp load_data(socket, tenant) do
    tenant = %Tenant{
      tenant
      | outgoing_mail_configuration_type:
          case tenant.outgoing_mail_configuration do
            %Smtp{} -> "smtp"
            nil -> nil
          end,
        outgoing_sms_configuration_type:
          case tenant.outgoing_sms_configuration do
            %Websms{} -> "websms"
            nil -> nil
          end
    }

    changeset = TenantContext.change_tenant(tenant)

    socket
    |> assign(
      tenant: tenant,
      changeset: changeset,
      versions: PaperTrail.get_versions(tenant)
    )
    |> maybe_block_navigation()
  end

  defp maybe_block_navigation(%{assigns: %{changeset: %{changes: changes}}} = socket) do
    if changes == %{} do
      push_event(socket, "unblock_navigation", %{})
    else
      push_event(socket, "block_navigation", %{})
    end
  end
end
