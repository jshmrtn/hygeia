defmodule HygeiaWeb.LayoutView do
  use HygeiaWeb, :view

  alias Hygeia.UserContext.User

  defp is_logged_in?(conn), do: not is_nil(get_auth(conn))

  defp get_auth(conn), do: Plug.Conn.get_session(conn, :auth)
end
