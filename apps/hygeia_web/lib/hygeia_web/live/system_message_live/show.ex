defmodule HygeiaWeb.SystemMessageLive.Show do
  @moduledoc false

  use HygeiaWeb, :surface_view

  alias Hygeia.Repo
  alias Hygeia.SystemMessageContext
  alias Hygeia.SystemMessageContext.SystemMessage
  alias Hygeia.TenantContext
  alias Hygeia.UserContext.Grant.Role
  alias Surface.Components.Form
  alias Surface.Components.Form.DateTimeLocalInput
  alias Surface.Components.Form.ErrorTag
  alias Surface.Components.Form.Field
  alias Surface.Components.Form.Input.InputContext
  alias Surface.Components.Form.TextArea
  alias Surface.Components.Link
  alias Surface.Components.LivePatch

  @impl Phoenix.LiveView
  def handle_params(%{"id" => id} = params, uri, socket) do
    system_message = SystemMessageContext.get_system_message!(id)

    socket =
      if authorized?(
           system_message,
           case socket.assigns.live_action do
             :edit -> :update
             :show -> :details
           end,
           get_auth(socket)
         ) do
        Phoenix.PubSub.subscribe(Hygeia.PubSub, "system_message:#{id}")

        load_data(socket, system_message)
      else
        socket
        |> push_redirect(to: Routes.home_path(socket, :index))
        |> put_flash(:error, gettext("You are not authorized to do this action."))
      end

    super(params, uri, socket)
  end

  @impl Phoenix.LiveView
  def handle_info({:updated, %SystemMessage{} = system_message}, socket) do
    {:noreply, assign(socket, :system_messages, system_message)}
  end

  def handle_info({:deleted, %SystemMessage{}, _version}, socket) do
    {:noreply, redirect(socket, to: Routes.system_message_index_path(socket, :index))}
  end

  def handle_info(_other, socket), do: {:noreply, socket}

  @impl Phoenix.LiveView
  def handle_event("reset", _params, socket) do
    system_message = SystemMessageContext.get_system_message!(socket.assigns.system_message.uuid)

    {:noreply,
     socket
     |> load_data(system_message)
     |> push_patch(to: Routes.system_message_show_path(socket, :show, system_message.uuid))
     |> maybe_block_navigation()}
  end

  def handle_event("validate", %{"system_message" => system_message_params}, socket) do
    {:noreply,
     socket
     |> assign(:changeset, %{
       SystemMessageContext.change_system_message(
         socket.assigns.system_message,
         system_message_params
       )
       | action: :validate
     })
     |> maybe_block_navigation()}
  end

  def handle_event("delete", _params, socket) do
    true = authorized?(socket.assigns.system_message, :delete, get_auth(socket))

    {:ok, _} = SystemMessageContext.delete_system_message(socket.assigns.system_message)

    {:noreply,
     socket
     |> put_flash(:info, gettext("System Message deleted successfully"))
     |> redirect(to: Routes.system_message_index_path(socket, :index))}
  end

  def handle_event("save", %{"system_message" => system_message_params}, socket) do
    true = authorized?(socket.assigns.system_message, :update, get_auth(socket))

    socket.assigns.system_message
    |> SystemMessageContext.update_system_message(system_message_params)
    |> case do
      {:ok, system_message} ->
        {:noreply,
         socket
         |> load_data(system_message)
         |> put_flash(:info, gettext("System Message updated successfully"))
         |> push_patch(to: Routes.system_message_show_path(socket, :show, system_message.uuid))}

      {:error, changeset} ->
        {:noreply,
         socket
         |> assign(changeset: changeset)
         |> maybe_block_navigation()}
    end
  end

  defp load_data(socket, system_message) do
    system_message = Repo.preload(system_message, related_tenants: [])

    changeset = SystemMessageContext.change_system_message(system_message)

    socket
    |> assign(
      system_message: system_message,
      changeset: changeset
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

  @spec roles :: [String.t()]
  def roles,
    do: Enum.map(Role.__enum_map__(), &{&1, &1})

  @spec tenants :: [{name :: String.t(), uuid :: String.t()}]
  def tenants,
    do:
      TenantContext.list_tenants()
      |> Enum.reject(&is_nil(&1.iam_domain))
      |> Enum.map(&{&1.name, &1.uuid})
end
