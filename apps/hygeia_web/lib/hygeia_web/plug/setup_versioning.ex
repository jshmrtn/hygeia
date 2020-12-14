defmodule HygeiaWeb.Plug.SetupVersioning do
  @moduledoc """
  Setup Versioning Plug
  """

  @behaviour Plug

  import Plug.Conn

  alias Hygeia.Helpers.Versioning

  @impl Plug
  def init(_opts) do
    nil
  end

  @impl Plug
  def call(conn, _opts) do
    Versioning.put_origin(:web)
    Versioning.put_originator(get_session(conn, :auth) || :noone)

    conn
  end
end
