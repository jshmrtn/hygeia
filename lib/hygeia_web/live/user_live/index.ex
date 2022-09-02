defmodule HygeiaWeb.UserLive.Index do
  @moduledoc false

  use HygeiaWeb, :surface_view

  alias Hygeia.Repo
  alias Hygeia.UserContext
  alias Hygeia.UserContext.User
  alias Surface.Components.LiveRedirect

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    socket =
      if authorized?(User, :list, get_auth(socket)) do
        Phoenix.PubSub.subscribe(Hygeia.PubSub, "users")

        assign(socket, :users, list_users())
      else
        socket
        |> push_redirect(to: Routes.home_index_path(socket, :index))
        |> put_flash(:error, gettext("You are not authorized to do this action."))
      end

    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def handle_params(params, _uri, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, gettext("Users"))
    |> assign(:user, nil)
  end

  @impl Phoenix.LiveView
  def handle_info({_type, %User{}, _version}, socket) do
    {:noreply, assign(socket, :users, list_users())}
  end

  def handle_info(_other, socket), do: {:noreply, socket}

  defp list_users, do: Repo.preload(UserContext.list_users(), :grants)
end
