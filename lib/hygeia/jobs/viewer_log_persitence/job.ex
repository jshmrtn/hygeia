defmodule Hygeia.Jobs.ViewerLogPersistence.Job do
  @moduledoc """
  Refresh Materialized View on a timer

  ## Start Options

  * `topic` (`required`) - PubSub Topic to listen on
  * `total` (`required`) - How many workers are running at the same time
  * `index` (`required`) - Which worker is this one
  * `max_timeout` (default 100ms) - How long to wait maximum
  * `max_items` (default 100) How many items to insert at the same time maximum
  """

  use GenServer

  alias Hygeia.AuditContext.ResourceView
  alias Hygeia.Repo

  @default_max_timeout 100
  @default_max_items 1000

  @spec start_link(opts :: Keyword.t()) :: GenServer.on_start()
  def start_link(opts),
    do:
      GenServer.start_link(
        __MODULE__,
        Keyword.take(opts, [:topic, :total, :index, :max_timeout, :max_items])
      )

  @spec child_spec(opts :: Keyword.t()) :: Supervisor.child_spec()
  def child_spec(opts), do: %{super(opts) | id: {__MODULE__, Keyword.fetch!(opts, :index)}}

  @impl GenServer
  def init(opts) do
    Process.flag(:trap_exit, true)

    :ok = Phoenix.PubSub.subscribe(Hygeia.PubSub, Keyword.fetch!(opts, :topic))

    :timer.send_interval(Keyword.get(opts, :max_timeout, @default_max_timeout), :timeout)

    {:ok,
     {[],
      opts
      |> Keyword.take([:total, :index, :max_items])
      |> Keyword.put_new(:max_items, @default_max_items)
      |> Map.new()}}
  end

  @impl GenServer
  def handle_info(:timeout, {[], opts}), do: {:noreply, {[], opts}}

  def handle_info(:timeout, {events, opts}) do
    flush(events)

    {:noreply, {[], opts}}
  end

  def handle_info(
        %{request_id: request_id} = event,
        {events, %{max_items: max_items, total: total, index: index} = opts}
      )
      when max_items >= length(events) + 1 do
    if rem(request_id, total) + 1 == index do
      flush([event | events])

      {:noreply, {[], opts}}
    else
      {:noreply, {events, opts}}
    end
  end

  def handle_info(
        %{request_id: request_id} = event,
        {events, %{total: total, index: index} = opts}
      ) do
    if rem(request_id, total) + 1 == index do
      {:noreply, {[event | events], opts}}
    else
      {:noreply, {events, opts}}
    end
  end

  def handle_info(_other, state), do: {:noreply, state}

  @impl GenServer
  def terminate(_reason, {[], opts}), do: {[], opts}

  def terminate(_reason, {events, opts}) do
    flush(events)

    {[], opts}
  end

  defp flush(events) do
    length = length(events)

    {^length, nil} =
      Repo.insert_all(ResourceView, events,
        returning: false,
        on_conflict: :replace_all,
        conflict_target: [
          :request_id,
          :action,
          :resource_table,
          :resource_pk
        ]
      )

    :ok
  end
end
