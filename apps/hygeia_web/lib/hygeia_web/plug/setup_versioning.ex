defmodule HygeiaWeb.Plug.SetupVersioning do
  @moduledoc """
  Setup Versioning Plug
  """

  @behaviour Plug

  import Plug.Conn

  alias Hygeia.Helpers.Versioning
  alias Hygeia.UserContext.User

  @impl Plug
  def init(_opts) do
    nil
  end

  @impl Plug
  def call(conn, _opts) do
    Versioning.put_origin(:web)

    conn
    |> get_session(:auth)
    |> case do
      nil ->
        conn

      %User{} = user ->
        Versioning.put_originator(user)

        conn
    end
  end
end
