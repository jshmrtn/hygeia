defmodule HygeiaWeb.UploadController do
  use HygeiaWeb, :controller

  @spec upload(conn :: Plug.Conn.t(), params :: %{String.t() => String.t()}) :: Plug.Conn.t()
  def upload(conn, %{"id" => id}) do
    {:ok, data, conn} = read_body(conn)

    Phoenix.PubSub.broadcast!(
      Hygeia.PubSub,
      "uploads:#{id}",
      {:upload, data, get_req_header(conn, "content-type")}
    )

    send_resp(conn, :no_content, "")
  end
end
