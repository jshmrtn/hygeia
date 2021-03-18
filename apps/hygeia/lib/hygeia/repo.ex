defmodule Hygeia.Repo do
  use Ecto.Repo,
    otp_app: :hygeia,
    adapter: Ecto.Adapters.Postgres

  use Paginator,
    limit: 25,
    maximum_limit: 100,
    include_total_count: true,
    total_count_primary_key_field: :uuid

  @spec listen(event_name :: String.t()) :: {:ok, reference} | {:error, term}
  def listen(event_name) do
    with {:ok, pid} <- Postgrex.Notifications.start_link(config()),
         {:ok, ref} <- Postgrex.Notifications.listen(pid, event_name) do
      {:ok, ref}
    else
      {:eventually, ref} -> {:ok, ref}
      {:error, reason} -> {:error, reason}
    end
  end
end
