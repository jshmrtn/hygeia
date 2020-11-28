defmodule Hygeia.Jobs.RefreshMaterializedView do
  @moduledoc """
  Refresh Materialized View on a timer

  ## Start Options

  * `name` (`required`) - GenServer Name
  * `view` (`required`) - `atom` name of the view to be refreshed
  * `interval_ms` (default 1 hour) - refresh interval in ms
  """

  use GenServer

  alias Hygeia.Repo

  case Mix.env() do
    :dev -> @default_refresh_interval_ms :timer.seconds(30)
    _env -> @default_refresh_interval_ms :timer.hours(1)
  end

  @spec start_link(opts :: Keyword.t()) :: GenServer.on_start()
  def start_link(opts),
    do:
      GenServer.start_link(__MODULE__, Keyword.take(opts, [:view, :interval_ms]),
        name: Keyword.fetch!(opts, :name)
      )

  @spec child_spec(opts :: Keyword.t()) :: Supervisor.child_spec()
  def child_spec(opts) do
    # credo:disable-for-next-line Credo.Check.Warning.UnsafeToAtom
    %{super(opts) | id: Module.concat(__MODULE__, Keyword.fetch!(opts, :view))}
  end

  @impl GenServer
  def init(opts) do
    interval_ms = Keyword.get(opts, :interval_ms, @default_refresh_interval_ms)

    Process.send_after(self(), {:start_interval, interval_ms}, :rand.uniform(interval_ms))

    {:ok, Keyword.fetch!(opts, :view)}
  end

  @impl GenServer
  def handle_info({:start_interval, interval_ms}, view) do
    :timer.send_interval(interval_ms, :refresh)
    send(self(), :refresh)

    {:noreply, view}
  end

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
    Repo.query!("REFRESH MATERIALIZED VIEW CONCURRENTLY #{view}", [], timeout: :timer.minutes(15))

    Phoenix.PubSub.broadcast!(Hygeia.PubSub, Atom.to_string(view), :refresh)
  end
end
