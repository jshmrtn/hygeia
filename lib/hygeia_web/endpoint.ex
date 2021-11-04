defmodule HygeiaWeb.Endpoint do
  use Sentry.PlugCapture
  use Phoenix.Endpoint, otp_app: :hygeia

  import PlugDynamic.Builder

  # The session will be stored in the cookie and signed,
  # this means its contents can be read but not tampered with.
  # Set :encryption_salt if you would also like to encrypt it.
  @session_options [
    store: HygeiaWeb.SessionStorage,
    key: "_hygeia_web_key",
    signing_salt: "yunZhVP3"
  ]

  socket "/socket", HygeiaWeb.UserSocket,
    websocket: true,
    longpoll: false

  socket "/live", Phoenix.LiveView.Socket,
    websocket: [connect_info: [:peer_data, :uri, session: @session_options]]

  plug RemoteIp, proxies: ~w[10.0.0.0/8 172.16.0.0/12 192.168.0.0/16 127.0.0.0/8 fc00::/7]

  # Serve at "/" the static files from "priv/static" directory.
  #
  # You should set gzip to true if you are running phx.digest
  # when deploying your static files in production.
  plug Plug.Static,
    at: "/",
    from: :hygeia,
    gzip: false,
    only: ~w(downloads css fonts images js favicon.ico robots.txt security.txt .well-known)

  plug Plug.Static, at: "/tenant-logos/", from: {__MODULE__, :tenant_logo_path, []}

  # Code reloading can be explicitly enabled under the
  # :code_reloader configuration of your endpoint.
  if code_reloading? do
    socket "/phoenix/live_reload/socket", Phoenix.LiveReloader.Socket
    plug Phoenix.LiveReloader
    plug Phoenix.CodeReloader
    plug Phoenix.Ecto.CheckRepoStatus, otp_app: :hygeia
  end

  plug Phoenix.LiveDashboard.RequestLogger,
    param_key: "request_logger",
    cookie_key: "request_logger"

  plug Plug.RequestId
  plug Plug.Telemetry, event_prefix: [:phoenix, :endpoint]

  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Phoenix.json_library()

  plug Sentry.PlugContext

  plug Plug.MethodOverride
  plug Plug.Head

  dynamic_plug Plug.Session, reevaluate: :first_usage do
    :hygeia
    |> Application.fetch_env!(HygeiaWeb.Endpoint)
    |> Keyword.get(:url)
    |> Keyword.get(:scheme)
    |> case do
      "https" -> @session_options ++ [secure: true]
      _other -> @session_options
    end
  end

  plug HygeiaWeb.Router

  @doc false
  @spec tenant_logo_path :: Path.t()
  def tenant_logo_path, do: Application.fetch_env!(:hygeia, :tenant_logo_root_path)
end
