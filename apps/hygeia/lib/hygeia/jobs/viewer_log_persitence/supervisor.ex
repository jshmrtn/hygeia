defmodule Hygeia.Jobs.ViewerLogPersistence.Supervisor do
  @moduledoc """
  Viewer Log Persistence Supervisor
  """

  use Supervisor

  alias Hygeia.AuditContext
  alias Hygeia.Jobs.ViewerLogPersistence.Job

  @spec start_link(opts :: Keyword.t()) :: Supervisor.on_start()
  def start_link(opts), do: Supervisor.start_link(__MODULE__, opts, name: __MODULE__)

  @impl Supervisor
  def init(opts),
    do: Supervisor.init(jobs(opts), strategy: :one_for_one, max_restarts: num_workers(opts) * 2)

  defp jobs(opts),
    do:
      Enum.map(
        1..num_workers(opts),
        &{Job, total: num_workers(opts), index: &1, topic: AuditContext.__log_topic__()}
      )

  defp num_workers(opts), do: Keyword.get(opts, :num_workers, System.schedulers_online() * 2)
end
