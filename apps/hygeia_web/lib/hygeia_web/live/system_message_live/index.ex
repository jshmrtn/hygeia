defmodule HygeiaWeb.SystemMessageLive.Index do
  @moduledoc false

  use HygeiaWeb, :surface_view

  alias Hygeia.SystemMessageContext
  alias Hygeia.SystemMessageContext.SystemMessage
  alias Surface.Components.Link
  alias Surface.Components.LivePatch
  alias Surface.Components.LiveRedirect

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    socket =
      if authorized?(SystemMessage, :list, get_auth(socket)) do
        Phoenix.PubSub.subscribe(Hygeia.PubSub, "system_messages")

        assign(socket, system_messages: list_system_messages())
      else
        socket
        |> push_redirect(to: Routes.home_index_path(socket, :index))
        |> put_flash(:error, gettext("You are not authorized to do this action."))
      end

    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def handle_event("delete", %{"id" => id}, socket) do
    system_message = SystemMessageContext.get_system_message!(id)

    true = authorized?(system_message, :delete, get_auth(socket))

    system_message
    |> SystemMessageContext.delete_system_message()
    |> case do
      {:ok, _system_message} ->
        {:noreply, assign(socket, :system_messages, list_system_messages())}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, changeset_error_flash(socket, changeset)}
    end
  end

  @impl Phoenix.LiveView
  def handle_info({_type, %SystemMessage{}, _version}, socket) do
    {:noreply, assign(socket, :system_messages, list_system_messages())}
  end

  def handle_info(_other, socket), do: {:noreply, socket}

  defp list_system_messages, do: SystemMessageContext.list_system_messages()
end
