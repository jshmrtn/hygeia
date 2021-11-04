defimpl Plug.Exception, for: DBConnection.ConnectionError do
  @moduledoc false

  @spec actions(Plug.Exception.t()) :: [Plug.Exception.action()]
  def actions(_error), do: []

  @spec status(Plug.Exception.t()) :: Plug.Conn.status()
  def status(_error), do: 502
end
