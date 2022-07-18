defmodule Hygeia.Jobs.DataPruning do
  @moduledoc """
  Prune data
  """

  use GenServer
  use Hygeia, :context

  @default_refresh_interval_ms :timer.hours(1)

  @spec start_link(otps :: Keyword.t()) :: GenServer.on_start()
  def start_link(opts),
    do:
      GenServer.start_link(__MODULE__, Keyword.take(opts, [:name, :interval_ms]),
        name: Keyword.fetch!(opts, :name)
      )

  @spec child_spec(opts :: Keyword.t()) :: Supervisor.child_spec()
  def child_spec(opts) do
    # credo:disable-for-next-line Credo.Check.Warning.UnsafeToAtom
    %{super(opts) | id: Module.concat(__MODULE__, Keyword.fetch!(opts, :name))}
  end

  @impl GenServer
  def init(opts) do
    interval_ms = Keyword.get(opts, :interval_ms, @default_refresh_interval_ms)

    Process.send_after(self(), {:start_interval, interval_ms}, :rand.uniform(interval_ms))

    {:ok, Keyword.fetch!(opts, :name)}
  end

  @impl GenServer
  def handle_info({:start_interval, interval_ms}, type) do
    :timer.send_interval(interval_ms, :execute)
    send(self(), :execute)

    {:noreply, type}
  end

  def handle_info(:execute, type) do
    execute_prune(type)

    {:noreply, type}
  end

  defp execute_prune(:resource_view),
    do:
      Repo.delete_all(
        from resource_view in "resource_views", where: resource_view.time < ago(2, "year")
      )
end
