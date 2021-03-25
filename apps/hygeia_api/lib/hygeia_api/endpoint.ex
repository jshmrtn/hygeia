defmodule HygeiaApi.Endpoint do
  use Sentry.PlugCapture
  use Phoenix.Endpoint, otp_app: :hygeia_api

  socket "/socket", HygeiaApi.UserSocket,
    websocket: true,
    longpoll: false

  plug RemoteIp, proxies: ~w[10.0.0.0/8 172.16.0.0/12 192.168.0.0/16 127.0.0.0/8 fc00::/7]

  plug Plug.Static,
    at: "/",
    from: :hygeia_api,
    gzip: false,
    only: ~w(robots.txt security.txt .well-known)

  # Code reloading can be explicitly enabled under the
  # :code_reloader configuration of your endpoint.
  if code_reloading? do
    plug Phoenix.CodeReloader
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

  plug CORSPlug, origin: [:self], headers: ["content-type"]

  plug HygeiaApi.Router
end
