import Config

case config_env() do
  :prod ->
    config :hygeia, HygeiaWeb.Endpoint, server: true

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
  pool_size: String.to_integer(System.get_env("DATABASE_POOL_SIZE", "10")),
  prepare: database_prepare

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

config :hygeia, HygeiaWeb.Endpoint,
  url: [
    host: System.get_env("WEB_EXTERNAL_HOST", "localhost"),
    port: System.get_env("WEB_EXTERNAL_PORT", "#{web_port}"),
    scheme: System.get_env("WEB_EXTERNAL_SCHEME", "http")
  ],
  http: [
    port: web_port,
    transport_options: [socket_opts: [:inet6]]
  ],
  secret_key_base: System.fetch_env!("SECRET_KEY_BASE")

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

config :logger,
  level:
    String.to_existing_atom(
      System.get_env(
        "LOG_LEVEL",
        case config_env() do
          :prod -> "info"
          :dev -> "debug"
          :test -> "debug"
        end
      )
    )

# Prometheus Exporter
config :hygeia, HygeiaTelemetry,
  port: "METRICS_PORT" |> System.get_env("9568") |> String.to_integer()

# IAM
iam_config = [
  issuer_or_config_endpoint: System.get_env("IAM_ISSUER", "https://issuer.zitadel.ch"),
  client_id: System.fetch_env!("WEB_IAM_CLIENT_ID"),
  client_secret: System.fetch_env!("WEB_IAM_CLIENT_SECRET"),
  local_endpoint:
    URI.to_string(%URI{
      host: System.get_env("WEB_EXTERNAL_HOST", "localhost"),
      scheme: System.get_env("WEB_EXTERNAL_SCHEME", "http"),
      port: "WEB_EXTERNAL_PORT" |> System.get_env("#{web_port}") |> String.to_integer(),
      path: "/auth/oidc/callback"
    }),
  request_scopes: ["openid", "profile", "email", "offline_access"]
]

config :hygeia, HygeiaIam,
  providers: [zitadel: iam_config],
  service_accounts: [
    user_sync: [
      login: System.fetch_env!("IAM_SERVICE_ACCOUNT_USER_SYNC_LOGIN")
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

config :hygeia, Hygeia.TenantContext, sedex_sender_id: System.fetch_env!("SEDEX_SENDER_ID")

config :hygeia, Hygeia.TenantContext.Tenant.Smtp,
  sender_hostname: System.get_env("SMTP_SENDER_HOSTNAME", "localhost")

config :hygeia, HygeiaIam,
  organisation_id: System.fetch_env!("IAM_ORGANISATION_ID"),
  project_id: System.fetch_env!("IAM_PROJECT_ID")

config :sentry,
  dsn: System.get_env("SENTRY_DSN"),
  tags: %{version: System.get_env("SENTRY_VERSION", System.get_env("RELEASE_VSN", "dev"))},
  environment_name: System.get_env("SENTRY_ENV", "local"),
  included_environments: [System.get_env("SENTRY_ENV")]

case System.fetch_env("PDF_CONFIRMATION_TEMPLATE_ROOT") do
  {:ok, path} -> config :hygeia, HygeiaPdfConfirmation, template_root_path: path
  :error -> nil
end

case System.fetch_env("TENANT_LOGO_TEMPLATE_ROOT") do
  {:ok, path} -> config :hygeia, tenant_logo_root_path: path
  :error -> nil
end

case Code.ensure_loaded(Sentry.LoggerBackend) do
  {:module, Sentry.LoggerBackend} -> config :logger, backends: [:console, Sentry.LoggerBackend]
  {:error, :nofile} -> nil
end

case Code.ensure_loaded(SentryEventFilter) do
  {:module, SentryEventFilter} -> config :sentry, filter: SentryEventFilter
  {:error, :nofile} -> nil
end
