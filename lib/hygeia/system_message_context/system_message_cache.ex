defmodule Hygeia.SystemMessageContext.SystemMessageCache do
  @moduledoc """
  System Messages ETS table, refresh on a timer
  """

  use GenServer
  use Hygeia, :context

  alias Hygeia.SystemMessageContext

  @default_refresh_interval_ms :timer.minutes(1)
  @ets_table_name Module.concat(__MODULE__, Table)
  @ets_new_table_name Module.concat(__MODULE__, NewTable)

  defstruct []

  @spec start_link(opts :: Keyword.t()) :: GenServer.on_start()
  def start_link(opts) do
    GenServer.start_link(__MODULE__, Keyword.take(opts, [:interval_ms]),
      name: Keyword.get(opts, :name, __MODULE__)
    )
  end

  @impl GenServer
  def init(opts) do
    Process.flag(:trap_exit, true)

    Phoenix.PubSub.subscribe(Hygeia.PubSub, "system_messages")

    update_ets_table()

    interval_ms = Keyword.get(opts, :interval_ms, @default_refresh_interval_ms)

    :timer.send_interval(interval_ms, :refresh)

    {:ok, %__MODULE__{}}
  end

  @impl GenServer
  def handle_info({action, _system_message, _version}, state)
      when action in [:updated, :created, :deleted] do
    update_ets_table()
    {:noreply, state}
  end

  def handle_info(:refresh, state) do
    update_ets_table()
    {:noreply, state}
  end

  def handle_info(_other, state), do: {:noreply, state}

  @impl GenServer
  def terminate(reason, _state) do
    @ets_table_name
    |> :ets.whereis()
    |> case do
      :undefined -> :ok
      old_tid -> :ets.delete(old_tid)
    end

    @ets_new_table_name
    |> :ets.whereis()
    |> case do
      :undefined -> :ok
      old_tid -> :ets.delete(old_tid)
    end

    reason
  end

  @spec refresh(server :: GenServer.server()) :: :ok
  def refresh(server) do
    GenServer.cast(server, :refresh)
  end

  defp update_ets_table do
    system_messages = SystemMessageContext.get_active_system_messages()

    new_tid =
      :ets.new(@ets_new_table_name, [
        :set,
        :protected,
        :named_table,
        read_concurrency: true
      ])

    for system_message <- system_messages do
      :ets.insert(
        new_tid,
        {system_message.uuid, system_message.text, system_message.roles,
         Enum.map(system_message.related_tenants, & &1.uuid)}
      )
    end

    @ets_table_name
    |> :ets.whereis()
    |> case do
      :undefined -> :ok
      old_tid -> :ets.delete(old_tid)
    end

    :ets.rename(new_tid, @ets_table_name)

    Phoenix.PubSub.broadcast!(Hygeia.PubSub, "system_message_cache", :refresh)
  end
end
