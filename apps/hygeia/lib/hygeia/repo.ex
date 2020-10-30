defmodule Hygeia.Repo do
  use Ecto.Repo,
    otp_app: :hygeia,
    adapter: Ecto.Adapters.Postgres

  use Paginator,
    limit: 25,
    maximum_limit: 100,
    include_total_count: true,
    total_count_primary_key_field: :uuid
end
