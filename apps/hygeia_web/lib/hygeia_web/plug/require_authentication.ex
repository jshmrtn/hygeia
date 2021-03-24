defmodule HygeiaWeb.Plug.RequireAuthentication do
  @moduledoc """
  Require Authentication Plug
  """

  @behaviour Plug

  import Plug.Conn
  import Phoenix.Controller

  alias Hygeia.CaseContext.Person
  alias Hygeia.UserContext.User
  alias HygeiaWeb.Router.Helpers

  @impl Plug
  def init(_opts) do
    nil
  end

  @impl Plug
  def call(%Plug.Conn{request_path: request_path} = conn, _opts) do
    conn
    |> get_session(:auth)
    |> case do
      nil ->
        conn
        |> redirect(to: Helpers.auth_login_path(conn, :login, return_url: request_path))
        |> halt

      %User{} ->
        conn

      %Person{} ->
        conn
    end
  end
end
