defmodule HygeiaWeb.Plug.HasRole do
  @moduledoc """
  Require Authentication Plug
  """

  @behaviour Plug

  import Plug.Conn
  import Phoenix.Controller

  alias Hygeia.UserContext.User
  alias HygeiaWeb.ErrorView

  @impl Plug
  def init(role) do
    role
  end

  @impl Plug
  def call(conn, role) do
    %User{} = user = get_session(conn, :auth)

    if User.has_role?(user, role) do
      conn
    else
      conn
      |> put_status(:forbidden)
      |> put_view(ErrorView)
      |> render("403.html")
      |> halt
    end
  end
end
