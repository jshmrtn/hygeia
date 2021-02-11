defmodule HygeiaWeb.UserLive.Show do
  @moduledoc false
  use HygeiaWeb, :surface_view

  alias Hygeia.Repo
  alias Hygeia.UserContext
  alias Hygeia.UserContext.Grant
  alias Hygeia.UserContext.User

  alias Surface.Components.LiveRedirect

  @impl Phoenix.LiveView
  def handle_params(%{"id" => id}, _uri, socket) do
    user =
      id
      |> UserContext.get_user!()
      |> Repo.preload(grants: [tenant: []])

    socket =
      if authorized?(user, :details, get_auth(socket)) do
        Phoenix.PubSub.subscribe(Hygeia.PubSub, "users:#{id}")

        assign(socket, :user, user)
      else
        socket
        |> push_redirect(to: Routes.home_path(socket, :index))
        |> put_flash(:error, gettext("You are not authorized to do this action."))
      end

    {:noreply, socket}
  end

  @impl Phoenix.LiveView
  def handle_info({:updated, %User{} = user, _versionr}, socket) do
    {:noreply, assign(socket, :user, user)}
  end

  def handle_info({:deleted, %User{}, _version}, socket) do
    {:noreply, redirect(socket, to: Routes.user_index_path(socket, :index))}
  end

  def handle_info(_other, socket), do: {:noreply, socket}
end
