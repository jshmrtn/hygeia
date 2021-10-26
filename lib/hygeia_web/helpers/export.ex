defmodule HygeiaWeb.Helpers.Export do
  @moduledoc """
  Export Helpers
  """

  @spec into_conn(chunks :: Enumerable.t(), conn :: Plug.Conn.t()) :: Plug.Conn.t()
  def into_conn(chunks, conn) do
    Enum.reduce_while(chunks, conn, fn chunk, conn ->
      case Plug.Conn.chunk(conn, chunk) do
        {:ok, conn} ->
          {:cont, conn}

        {:error, :closed} ->
          {:halt, conn}
      end
    end)
  end
end
