defmodule Hygeia.SedexExport.SchedulerCoordinator do
  @moduledoc """
  Ensures that each enabled tenant has one scheduler running
  """

  use GenServer

  alias Hygeia.SedexExport.Scheduler
  alias Hygeia.SedexExport.SchedulerSupervisor
  alias Hygeia.TenantContext
  alias Hygeia.TenantContext.Tenant

  @type t :: %__MODULE__{
          scheduler_supervisor: Supervisor.supervisor(),
          schedulers: %{optional(String.t()) => {Tenant.t(), GenServer.server()}}
        }

  @default_refresh_interval_ms (case(Mix.env()) do
                                  :dev -> :timer.seconds(30)
                                  _env -> :timer.minutes(5)
                                end)

  defstruct [:scheduler_supervisor, schedulers: %{}]

  @spec start_link(opts :: Keyword.t()) :: GenServer.on_start()
  def start_link(opts),
    do:
      GenServer.start_link(__MODULE__, Keyword.take(opts, [:scheduler_supervisor]),
        name: Keyword.get(opts, :name, __MODULE__)
      )

  @impl GenServer
  def init(opts) do
    Phoenix.PubSub.subscribe(Hygeia.PubSub, "tenants")

    interval_ms = Keyword.get(opts, :refresh_interval_ms, @default_refresh_interval_ms)

    Process.send_after(self(), {:start_interval, interval_ms}, :rand.uniform(interval_ms))

    {:ok,
     %__MODULE__{
       scheduler_supervisor: Keyword.get(opts, :scheduler_supervisor, SchedulerSupervisor),
       schedulers: %{}
     }}
  end

  @impl GenServer
  def handle_info({:start_interval, interval_ms}, state) do
    :timer.send_interval(interval_ms, :refresh)
    send(self(), :refresh)

    {:noreply, state}
  end

  def handle_info(:refresh, state), do: {:noreply, refresh_schedulers(state)}

  def handle_info({_action, %Tenant{} = _tenant, _version}, state),
    do: {:noreply, refresh_schedulers(state)}

  def handle_info(_other, state), do: {:noreply, state}

  defp refresh_schedulers(
         %__MODULE__{scheduler_supervisor: scheduler_supervisor, schedulers: schedulers} = state
       ) do
    enabled_tenants =
      Enum.filter(TenantContext.list_tenants(), &match?(%Tenant{sedex_export_enabled: true}, &1))

    schedulers =
      schedulers
      |> Enum.filter(fn {uuid, {_tenant, pid}} ->
        if Enum.any?(enabled_tenants, &(&1.uuid == uuid)) do
          true
        else
          :ok = DynamicSupervisor.terminate_child(scheduler_supervisor, pid)

          false
        end
      end)
      |> Map.new()

    schedulers =
      Enum.reduce(enabled_tenants, schedulers, fn %Tenant{uuid: uuid} = tenant, acc ->
        case acc do
          %{^uuid => {^tenant, _pid}} ->
            acc

          %{^uuid => {_old_tenant, pid}} ->
            :ok = DynamicSupervisor.terminate_child(scheduler_supervisor, pid)

            {:ok, pid} =
              DynamicSupervisor.start_child(
                scheduler_supervisor,
                {Highlander, {Scheduler, tenant: tenant}}
              )

            Map.put(acc, uuid, {tenant, pid})

          %{} ->
            {:ok, pid} =
              DynamicSupervisor.start_child(
                scheduler_supervisor,
                {Highlander, {Scheduler, tenant: tenant}}
              )

            Map.put(acc, uuid, {tenant, pid})
        end
      end)

    %__MODULE__{state | schedulers: schedulers}
  end
end
