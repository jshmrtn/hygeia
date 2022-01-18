defmodule HygeiaWeb.Helpers.Auth do
  @moduledoc false

  alias Hygeia.CaseContext.Person
  alias Hygeia.UserContext.User

  @spec is_logged_in?(conn_or_socket :: Plug.Conn.t() | Phoenix.LiveView.Socket.t()) :: boolean
  def is_logged_in?(conn_or_socket), do: get_auth(conn_or_socket) != :anonymous

  @spec get_auth(conn_or_socket :: Plug.Conn.t() | Phoenix.LiveView.Socket.t()) ::
          :anonymous | User.t() | Person.t()
  def get_auth(%Plug.Conn{private: %{plug_session: _}} = conn),
    do: Plug.Conn.get_session(conn, :auth) || :anonymous

  def get_auth(%Plug.Conn{} = _conn), do: :anonymous

  def get_auth(%Phoenix.LiveView.Socket{private: private, assigns: assigns} = socket) do
    private[:conn_session]["auth"] || socket_session(socket)["auth"] ||
      case assigns do
        %{__context__: ctx} -> ctx[{HygeiaWeb, :auth}]
        _other -> :anonymous
      end || :anonymous
  end

  defp socket_session(%Phoenix.LiveView.Socket{private: private}) do
    case private[:connect_info] do
      %{session: session} -> session
      _other -> nil
    end
  end
end
