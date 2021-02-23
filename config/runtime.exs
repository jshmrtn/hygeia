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

database_prepare =
  case System.get_env("DATABASE_PREPARE", "named") do
    "named" -> :named
    "unnamed" -> :unnamed
    other -> raise "Invalid value #{inspect(other)} for env DATABASE_PREPARE"
  end

config :hygeia, Hygeia.Repo,
  ssl: database_ssl,
  backoff_type: :stop,
  port: System.get_env("DATABASE_PORT", "5432"),
  username: System.get_env("DATABASE_USER", "root"),
  password: System.get_env("DATABASE_PASSWORD", ""),
  database: System.get_env("DATABASE_NAME", "hygeia_#{config_env()}"),
  hostname: System.get_env("DATABASE_HOST", "localhost"),
  pool_size: String.to_integer(System.get_env("DATABASE_POOL_SIZE", "10"))

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
iam_config = [
  issuer_or_config_endpoint: System.get_env("IAM_ISSUER", "https://issuer.zitadel.ch"),
  client_id: System.get_env("WEB_IAM_CLIENT_ID", "***REMOVED***"),
  client_secret:
    System.get_env(
      "WEB_IAM_CLIENT_SECRET",
      "***REMOVED***"
    ),
  local_endpoint:
    URI.to_string(%URI{
      host: System.get_env("WEB_EXTERNAL_HOST", "localhost"),
      scheme: System.get_env("WEB_EXTERNAL_SCHEME", "http"),
      port: "WEB_EXTERNAL_PORT" |> System.get_env("#{web_port}") |> String.to_integer(),
      path: "/auth/oidc/callback"
    }),
  request_scopes: ["openid", "profile", "email"]
]

config :hygeia_iam, :providers, zitadel: iam_config

config :hygeia_iam, :service_accounts,
  user_sync: [
    login:
      System.get_env(
        "IAM_SERVICE_ACCOUNT_USER_SYNC_LOGIN",
        ~S"""
        {
          "type": "serviceaccount",
          "keyId": "***REMOVED***",
          "key": "-----BEGIN RSA PRIVATE KEY-----\n***REMOVED***\n***REMOVED***\n***REMOVED***\n***REMOVED***\n***REMOVED***\n***REMOVED***\n***REMOVED***\n***REMOVED***\n***REMOVED***\n***REMOVED***\n***REMOVED***\n***REMOVED***\n***REMOVED***\n***REMOVED***\n***REMOVED***\n***REMOVED***\n***REMOVED***\n***REMOVED***\n***REMOVED***\n***REMOVED***\n***REMOVED***\n***REMOVED***\n***REMOVED***\n***REMOVED***\n***REMOVED***\n-----END RSA PRIVATE KEY-----\n",
          "userId": "***REMOVED***"
        }
        """
      ),
    audience: [
      "https://api.zitadel.ch/oauth/v2/token",
      "https://api.zitadel.ch/"
    ]
  ]

case System.fetch_env("DKIM_PATH") do
  {:ok, path} -> config :hygeia, dkim_certificate_directory: path
  :error -> nil
end

case System.get_env("SEDEX_FILESYSTEM_ADAPTER", "filesystem") do
  "filesystem" ->
    config :sedex, Sedex.Storage, adapter: Sedex.Storage.Filesystem

  "minio" ->
    config :sedex, Sedex.Storage, adapter: Sedex.Storage.Minio

    config :sedex, Sedex.Storage.Minio,
      access_key_id: System.get_env("SEDEX_FILESYSTEM_MINIO_USER", "root"),
      secret_access_key: System.get_env("SEDEX_FILESYSTEM_MINIO_PASSWORD", "rootroot"),
      scheme: System.get_env("SEDEX_FILESYSTEM_MINIO_SCHEME", "http") <> "://",
      port: "SEDEX_FILESYSTEM_MINIO_PORT" |> System.get_env("9000") |> String.to_integer(),
      host: System.get_env("SEDEX_FILESYSTEM_MINIO_HOST", "localhost")

  other ->
    raise "#{other} is not a valid value for SEDEX_FILESYSTEM_ADAPTER"
end

config :hygeia, Hygeia.TenantContext,
  sedex_sender_id: System.get_env("SEDEX_SENDER_ID", "***REMOVED***")

config :hygeia, Hygeia.TenantContext.Tenant.Smtp,
  sender_hostname: System.get_env("SMTP_SENDER_HOSTNAME", "smtp.covid19-tracing.ch")

config :hygeia_iam,
  organisation_id: System.get_env("IAM_ORGANISATION_ID", "***REMOVED***"),
  project_id: System.get_env("IAM_PROJECT_ID", "***REMOVED***")

config :sentry,
  dsn:
    System.get_env(
      "SENTRY_DSN",
      "https://***REMOVED***:***REMOVED***@sentry.joshmartin.ch/2"
    ),
  tags: %{version: System.get_env("SENTRY_VERSION", System.get_env("RELEASE_VSN", "dev"))},
  environment_name: System.get_env("SENTRY_ENV", "local"),
  included_environments: [System.get_env("SENTRY_ENV")]
