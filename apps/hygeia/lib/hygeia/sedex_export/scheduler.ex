defmodule Hygeia.SedexExport.Scheduler do
  @moduledoc """
  Runs Sedex Export as per configured schedule
  """

  use GenServer

  alias Hygeia.Helpers.Versioning
  alias Hygeia.TenantContext
  alias Hygeia.TenantContext.SedexExport
  alias Hygeia.TenantContext.Tenant

  require Logger

  @skip_threshold :timer.hours(1)
  @status_check_interval_ms :timer.seconds(30)
  @status_check_lost_interval_ms :timer.minutes(30)

  @type t :: %__MODULE__{
          tenant: Tenant.t(),
          last_run_date: NaiveDateTime.t() | nil,
          next_run_date: NaiveDateTime.t() | nil
        }

  defstruct [:tenant, :last_run_date, :next_run_date]

  @spec start_link(opts :: Keyword.t()) :: GenServer.on_start()
  def start_link(opts),
    do:
      GenServer.start_link(__MODULE__, Keyword.take(opts, [:tenant]), Keyword.take(opts, [:name]))

  @spec child_spec(opts :: Keyword.t()) :: Supervisor.child_spec()
  def child_spec(opts) do
    tenant = Keyword.fetch!(opts, :tenant)
    super_child_spec = super(opts)
    %{super_child_spec | id: "#{__MODULE__}.#{tenant.uuid}"}
  end

  @impl GenServer
  def init(opts) do
    Versioning.put_originator(:noone)
    Versioning.put_origin(:email_sender)

    tenant = Keyword.fetch!(opts, :tenant)
    sedex_export = TenantContext.last_sedex_export(tenant)

    last_run_date =
      case sedex_export do
        nil -> nil
        %SedexExport{scheduling_date: scheduling_date} -> scheduling_date
      end

    next_run_date =
      next_run_date(tenant.sedex_export_configuration.schedule, last_run_date, tenant)

    :ok = schedule_message(next_run_date)

    state = %__MODULE__{
      tenant: Keyword.fetch!(opts, :tenant),
      last_run_date: last_run_date,
      next_run_date: next_run_date
    }

    case sedex_export do
      nil ->
        {:ok, state}

      %SedexExport{status: :sent} ->
        {:ok, state,
         {:continue, {:wait_for_export, @status_check_lost_interval_ms, sedex_export}}}

      %SedexExport{} ->
        {:ok, state}
    end
  end

  @impl GenServer
  def handle_info(
        :trigger_job,
        %__MODULE__{next_run_date: current_run_date, tenant: tenant} = state
      ) do
    case NaiveDateTime.diff(NaiveDateTime.utc_now(), current_run_date, :millisecond) do
      time when time < 0 ->
        # Too Early
        :ok = schedule_message(current_run_date)

        {:noreply, state}

      time when time > @skip_threshold ->
        Logger.warn("""
        Too late to do export #{current_run_date} for tenant #{tenant.uuid}
        """)

        {:ok, %SedexExport{}} =
          TenantContext.create_sedex_export(tenant, %{
            status: :missed,
            scheduling_date: current_run_date
          })

        next_run_date =
          next_run_date(tenant.sedex_export_configuration.schedule, current_run_date, tenant)

        :ok = schedule_message(next_run_date)

        {:noreply, %__MODULE__{state | next_run_date: next_run_date}}

      time when time >= 0 and time < @skip_threshold ->
        Logger.info("""
        Executing Sedex Export #{current_run_date} for tenant #{tenant.uuid}
        """)

        {:ok, %SedexExport{} = export} = TenantContext.run_sedex_export(tenant, current_run_date)

        next_run_date =
          next_run_date(
            tenant.sedex_export_configuration.schedule,
            export.scheduling_date,
            tenant
          )

        :ok = schedule_message(next_run_date)

        {:noreply, %__MODULE__{state | next_run_date: next_run_date},
         {:continue, {:wait_for_export, @status_check_lost_interval_ms, export}}}
    end
  end

  def handle_info(_other, state), do: {:noreply, state}

  @impl GenServer
  def handle_continue(
        {:wait_for_export, remaining_wait_time_ms, export},
        %__MODULE__{tenant: tenant} = state
      )
      when remaining_wait_time_ms <= 0 do
    Logger.warn("""
    Delivery of Sedex Export #{export.scheduling_date} took to long for tenant #{tenant.uuid}, giving up:
    """)

    {:ok, _export} = TenantContext.update_sedex_export(export, %{status: :error})

    :ok = Sedex.cleanup(export.uuid)

    {:noreply, state}
  end

  def handle_continue(
        {:wait_for_export, remaining_wait_time_ms, export},
        %__MODULE__{tenant: tenant} = state
      )
      when remaining_wait_time_ms > 0 do
    case Sedex.message_status(export.uuid) do
      {:error, :not_found} ->
        Logger.info("""
        Delivery of Sedex Export #{export.scheduling_date} is not yet finished for tenant #{
          tenant.uuid
        }, waiting
        """)

        Process.sleep(@status_check_interval_ms)

        {:noreply, state,
         {:continue,
          {:wait_for_export, remaining_wait_time_ms - @status_check_interval_ms, export}}}

      {:ok, :message_correctly_transmitted, _message} ->
        {:ok, _export} = TenantContext.update_sedex_export(export, %{status: :received})

        :ok = Sedex.cleanup(export.uuid)

        {:noreply, state}

      {:ok, status, message} ->
        Logger.warn("""
        Delivery of Sedex Export #{export.scheduling_date} failed for tenant #{tenant.uuid}:
        #{inspect(status)}: #{message}
        """)

        {:ok, _export} = TenantContext.update_sedex_export(export, %{status: :error})

        :ok = Sedex.cleanup(export.uuid)

        {:noreply, state}
    end
  end

  defp next_run_date(cron_expression, last_run_date, tenant) do
    case _next_run_date(cron_expression, last_run_date) do
      {:ok, date} ->
        date

      {:error, reason} ->
        Logger.warn("""
        Can't figure out the next run date for Sedex Export Scheduler for tenant #{tenant.uuid}:
        #{inspect(reason, pretty: true)}
        """)

        nil
    end
  end

  defp _next_run_date(cron_expression, last_run_date)

  defp _next_run_date(cron_expression, nil),
    do: Crontab.Scheduler.get_next_run_date(cron_expression)

  defp _next_run_date(cron_expression, %NaiveDateTime{} = last_run_date),
    do:
      Crontab.Scheduler.get_next_run_date(
        cron_expression,
        NaiveDateTime.add(last_run_date, 1, :second)
      )

  defp schedule_message(date)
  defp schedule_message(nil), do: :ok

  defp schedule_message(date) do
    case NaiveDateTime.diff(date, NaiveDateTime.utc_now(), :millisecond) do
      time when time > 0 -> Process.send_after(self(), :trigger_job, time)
      time when time < 1 -> send(self(), :trigger_job)
    end

    :ok
  end
end
