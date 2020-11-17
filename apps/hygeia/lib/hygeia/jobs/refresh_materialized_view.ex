defmodule Hygeia.Jobs.RefreshMaterializedView do
  @moduledoc """
  Refresh Materialized View on a timer

  ## Start Options

  * `name` (`required`) - GenServer Name
  * `view` (`required`) - `atom` name of the view to be refreshed
  * `interval_ms` (default 5 minutes) - refresh interval in ms
  """

  use GenServer

  alias Ecto.Adapters.SQL

  case Mix.env() do
    :dev -> @default_refresh_interval_ms :timer.seconds(30)
    _env -> @default_refresh_interval_ms :timer.minutes(5)
  end

  @spec start_link(opts :: Keyword.t()) :: GenServer.on_start()
  def start_link(opts) do
    __MODULE__
    |> GenServer.start_link(Keyword.take(opts, [:view, :interval_ms]),
      name: Keyword.fetch!(opts, :name)
    )
    |> case do
      {:ok, pid} ->
        {:ok, pid}

      {:error, {:already_started, pid}} ->
        Process.link(pid)
        {:ok, pid}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @impl GenServer
  def init(opts) do
    :timer.send_interval(Keyword.get(opts, :interval_ms, @default_refresh_interval_ms), :refresh)
    send(self(), :refresh)

    {:ok, Keyword.fetch!(opts, :view)}
  end

  @impl GenServer
  def handle_info(:refresh, view) do
    execute_refresh(view)

    {:noreply, view}
  end

  @impl GenServer
  def handle_cast(:refresh, view) do
    execute_refresh(view)

    {:noreply, view}
  end

  @spec refresh(server :: GenServer.server()) :: :ok
  def refresh(server) do
    GenServer.cast(server, :refresh)
  end

  defp execute_refresh(view) do
    SQL.query!(Hygeia.Repo, "REFRESH MATERIALIZED VIEW CONCURRENTLY #{view}")

    Phoenix.PubSub.broadcast!(Hygeia.PubSub, Atom.to_string(view), :refresh)
  end
end
