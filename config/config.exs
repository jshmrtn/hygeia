import Config

# Configure Mix tasks and generators
config :hygeia,
  ecto_repos: [Hygeia.Repo],
  phone_number_parsing_origin_country: "CH",
  generators: [context_app: :hygeia, binary_id: true]

# Configures if contact persons are captured
config :hygeia, :quarantine_enabled, false

config :hygeia, Hygeia.Repo,
  migration_timestamps: [type: :utc_datetime_usec],
  migration_primary_key: [name: :uuid, type: :binary_id],
  migration_foreign_key: [column: :uuid, type: :binary_id],
  start_apps_before_migration: [:ssl]

# Configures the endpoint
config :hygeia, HygeiaWeb.Endpoint,
  render_errors: [
    view: HygeiaWeb.ErrorView,
    accepts: ~w(html json),
    layout: {HygeiaWeb.LayoutView, "error.html"},
    root_layout: {HygeiaWeb.LayoutView, "root.html"}
  ],
  pubsub_server: Hygeia.PubSub,
  live_view: [signing_salt: "S3zkaQcW"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

config :logger, compile_time_purge_matching: [[application: :remote_ip]]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Cadastre only do required languages
config :cadastre, Cadastre.I18n,
  default_locale: "en",
  allowed_locales: ["de", "en", "fr", "it"]

config :hygeia, HygeiaGettext, fuzzy_languages: ["it", "fr"]

# Prometheus Exporter
config :hygeia, HygeiaTelemetry, server: true

# OIDC
config :oidcc, http_request_timeout: 60, cert_depth: 5

# Nebulex Sessions
config :hygeia, HygeiaWeb.SessionStorage.Storage,
  stats: true,
  primary: [
    # 100Mb
    allocated_memory: 100_000_000,
    gc_interval: :timer.hours(24),
    gc_cleanup_min_timeout: :timer.seconds(10),
    gc_cleanup_max_timeout: :timer.seconds(30),
    max_size: 1_000_000
  ]

# Bamboo Mailer
config :hygeia, Hygeia.EmailSender.Smtp, adapter: Bamboo.SMTPAdapter

config :elixir, :time_zone_database, Tzdata.TimeZoneDatabase

# Surface
config :surface, :components, [
  {Surface.Components.Form.ErrorTag,
   default_translator: {HygeiaWeb.ErrorHelpers, :translate_error}}
]

# AWS (Minio)
config :ex_aws,
  json_codec: Jason

config :sentry, enable_source_code_context: true, root_source_code_path: File.cwd!()

config :hygeia, Hygeia.Jobs.SendCaseClosedEmail,
  url_generator: HygeiaWeb.SendCaseClosedEmailUrlGenerator

config :hygeia, Hygeia.AutoTracingContext.AutoTracingCommunication,
  url_generator: HygeiaWeb.AutoTracingCommunicationUrlGenerator

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
