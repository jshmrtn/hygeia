import Config

case config_env() do
  :prod ->
    config :hygeia_web, HygeiaWeb.Endpoint, server: true
    config :hygeia_api, HygeiaApi.Endpoint, server: true

  _env ->
    nil
end

database_ssl =
  case System.get_env("DATABASE_SSL", "false") do
    truthy when truthy in ["true", "1"] -> true
    _falsy -> false
  end

config :hygeia, Hygeia.Repo,
  ssl: database_ssl,
  username: System.get_env("DATABASE_USER", "root"),
  password: System.get_env("DATABASE_PASSWORD", ""),
  database: System.get_env("DATABASE_NAME", "hygeia_#{config_env()}"),
  hostname: System.get_env("DATABASE_HOST", "localhost"),
  pool_size: String.to_integer(System.get_env("POOL_SIZE", "10"))

secret_key_base =
  System.get_env(
    "SECRET_KEY_BASE",
    "***REMOVED***"
  )

web_port =
  String.to_integer(
    System.get_env(
      "WEB_PORT",
      case config_env() do
        :test -> "5000"
        _env -> "4000"
      end
    )
  )

config :hygeia_web, HygeiaWeb.Endpoint,
  url: [
    host: System.get_env("WEB_EXTERNAL_HOST", "localhost"),
    port: System.get_env("WEB_EXTERNAL_PORT", "#{web_port}"),
    scheme: System.get_env("WEB_EXTERNAL_SCHEME", "http")
  ],
  http: [
    port: web_port,
    transport_options: [socket_opts: [:inet6]]
  ],
  secret_key_base: secret_key_base

api_port =
  String.to_integer(
    System.get_env(
      "API_PORT",
      case config_env() do
        :test -> "5001"
        _env -> "4001"
      end
    )
  )

config :hygeia_api, HygeiaApi.Endpoint,
  url: [
    host: System.get_env("API_EXTERNAL_HOST", "localhost"),
    port: System.get_env("API_EXTERNAL_PORT", "#{api_port}"),
    scheme: System.get_env("API_EXTERNAL_SCHEME", "http")
  ],
  http: [
    port: api_port,
    transport_options: [socket_opts: [:inet6]]
  ],
  secret_key_base: secret_key_base

# Prometheus Exporter
config :hygeia_telemetry, port: "METRICS_PORT" |> System.get_env("9568") |> String.to_integer()

# IAM
config :ueberauth, UeberauthOIDC,
  zitadel: [
    issuer_or_config_endpoint: System.get_env("WEB_IAM_ISSUER", "https://issuer.zitadel.ch"),
    client_id: System.get_env("WEB_IAM_CLIENT_ID", "***REMOVED***"),
    client_secret:
      System.get_env(
        "WEB_IAM_CLIENT_SECRET",
        "***REMOVED***"
      ),
    request_scopes: ["openid", "profile", "email"]
  ]

# Sms
config :hygeia, Hygeia.SmsSender.WebSms,
  access_token: System.get_env("WEBSMS_ACCESS_TOKEN", "***REMOVED***")
