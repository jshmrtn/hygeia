defmodule Hygeia.Repo do
  use Ecto.Repo,
    otp_app: :hygeia,
    adapter: Ecto.Adapters.Postgres
end
