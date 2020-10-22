import Config

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :hygeia, Hygeia.Repo, pool: Ecto.Adapters.SQL.Sandbox

# DO not check emails MX in test
config :email_checker,
  validations: [EmailChecker.Check.Format]

# Prometheus Exporter
config :hygeia_telemetry, server: false

# Print only warnings and errors during test
config :logger, level: :warn
