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
  ecto_repos: [Hygeia.Repo]

config :hygeia, Hygeia.Repo,
  migration_timestamps: [type: :utc_datetime_usec],
  migration_primary_key: [name: :uuid, type: :binary_id],
  migration_foreign_key: [column: :uuid, type: :binary_id]

config :paper_trail,
  item_type: Ecto.UUID,
  originator_type: Ecto.UUID,
  timestamps_type: :utc_datetime_usec,
  repo: Hygeia.Repo,
  originator: [name: :user, model: Hygeia.UserContext.User]

config :hygeia_web,
  ecto_repos: [Hygeia.Repo],
  generators: [context_app: :hygeia, binary_id: true]

config :hygeia_api,
  ecto_repos: [Hygeia.Repo],
  generators: [context_app: :hygeia, binary_id: true]

# Configures the endpoint
config :hygeia_web, HygeiaWeb.Endpoint,
  render_errors: [view: HygeiaWeb.ErrorView, accepts: ~w(html json), layout: false],
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

# Mute unsupported metrics b< prometheus reporter
config :logger,
  compile_time_purge_matching: [
    [
      level_lower_than: :error,
      application: :telemetry_metrics_prometheus_core,
      module: TelemetryMetricsPrometheus.Core.Registry,
      function: "register_metrics/2"
    ]
  ]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Cadastre only do required languages
config :cadastre, Cadastre.I18n,
  default_locale: "en",
  allowed_locales: ["de", "en", "fr", "it"]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
