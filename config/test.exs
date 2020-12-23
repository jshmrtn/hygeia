import Config

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :hygeia, Hygeia.Repo,
  pool: Ecto.Adapters.SQL.Sandbox,
  timeout: :infinity,
  ownership_timeout: :infinity

config :hygeia, sms_sender: Hygeia.SmsSenderMock

# DO not check emails MX in test
config :email_checker,
  validations: [EmailChecker.Check.Format]

# Prometheus Exporter
config :hygeia_telemetry, server: false

# Print only warnings and errors during test
config :logger, level: :warn

# Bamboo Mailer
config :hygeia, Hygeia.EmailSender.Smtp, adapter: Bamboo.TestAdapter

# ExUnit
config :ex_unit, timeout: :infinity
