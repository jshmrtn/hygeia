# This file is responsible for configuring your umbrella
# and **all applications** and their dependencies with the
# help of Mix.Config.
#
# Note that all applications in your umbrella share the
# same configuration and dependencies, which is why they
# all use the same configuration file. If you want different
# configurations or dependencies per app, it is best to
# move said applications out of the umbrella.
import Config

# Configure Mix tasks and generators
config :hygeia,
  ecto_repos: [Hygeia.Repo],
  phone_number_parsing_origin_country: "CH"

config :hygeia, Hygeia.Repo,
  migration_timestamps: [type: :utc_datetime_usec],
  migration_primary_key: [name: :uuid, type: :binary_id],
  migration_foreign_key: [column: :uuid, type: :binary_id]

config :hygeia_web,
  ecto_repos: [Hygeia.Repo],
  generators: [context_app: :hygeia, binary_id: true]

config :hygeia_api,
  ecto_repos: [Hygeia.Repo],
  generators: [context_app: :hygeia, binary_id: true]

# Configures the endpoint
config :hygeia_web, HygeiaWeb.Endpoint,
  render_errors: [
    view: HygeiaWeb.ErrorView,
    accepts: ~w(html json),
    layout: {HygeiaWeb.LayoutView, "error.html"},
    root_layout: {HygeiaWeb.LayoutView, "root.html"}
  ],
  pubsub_server: Hygeia.PubSub,
  live_view: [signing_salt: "S3zkaQcW"]

config :hygeia_api, HygeiaApi.Endpoint,
  render_errors: [view: HygeiaApi.ErrorView, accepts: ~w(json), layout: false],
  pubsub_server: Hygeia.PubSub,
  live_view: [signing_salt: "eLUX7ihG"]

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

config :hygeia_gettext, HygeiaGettext, fuzzy_languages: ["it", "fr"]

# Prometheus Exporter
config :hygeia_telemetry, server: true

# OIDC
config :oidcc, http_request_timeout: 60

# Nebulex Sessions
config :hygeia_web, HygeiaWeb.SessionStorage.Storage,
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

config :sentry,
  enable_source_code_context: true,
  root_source_code_path:
    __ENV__.file |> Path.dirname() |> Path.dirname() |> Path.join("apps/*") |> Path.wildcard()

config :hygeia, Hygeia.Jobs.SendCaseClosedEmail,
  url_generator: HygeiaWeb.SendCaseClosedEmailUrlGenerator

config :hygeia, Hygeia.AutoTracingContext.AutoTracingCommunication,
  url_generator: HygeiaWeb.AutoTracingCommunicationUrlGenerator

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
