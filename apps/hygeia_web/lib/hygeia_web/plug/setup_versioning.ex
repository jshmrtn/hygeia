defmodule HygeiaWeb.Plug.SetupVersioning do
  @moduledoc """
  Setup Versioning Plug
  """

  @behaviour Plug

  import Plug.Conn

  alias Hygeia.CaseContext.Person
  alias Hygeia.Helpers.Versioning
  alias Hygeia.UserContext.User

  @impl Plug
  def init(_opts) do
    nil
  end

  @impl Plug
  def call(conn, _opts) do
    Versioning.put_origin(:web)

    case get_session(conn, :auth) do
      %User{} = user -> Versioning.put_originator(user)
      # TODO: Incorporate Person into Versioning
      %Person{} -> Versioning.put_originator(:noone)
      nil -> Versioning.put_originator(:noone)
    end

    conn
  end
end
