defmodule HygeiaWeb.Init.Auth do
  @moduledoc """
  Load Auth on mount
  """

  alias Hygeia.CaseContext.Person
  alias Hygeia.Helpers.Versioning
  alias Hygeia.UserContext.User

  @spec mount(
          Phoenix.LiveView.unsigned_params() | :not_mounted_at_router,
          session :: map,
          socket :: Phoenix.LiveView.Socket.t()
        ) :: {:cont | :halt, Phoenix.LiveView.Socket.t()}
  def mount(_params, session, socket) do
    case session["auth"] do
      %{uuid: id, email: email, display_name: name} ->
        Sentry.Context.set_user_context(%{id: id, email: email, name: name})

      _other ->
        :ok
    end

    Versioning.put_origin(:web)

    case session["auth"] do
      %User{} = user -> Versioning.put_originator(user)
      # TODO: Incorporate Person into Versioning
      %Person{} -> Versioning.put_originator(:noone)
      nil -> Versioning.put_originator(:noone)
    end

    {:cont, socket}
  end
end
