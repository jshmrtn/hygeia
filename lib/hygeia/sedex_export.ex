defmodule Hygeia.SedexExport do
  @moduledoc """
  Supervisor for Sedex Exports
  """

  use Supervisor

  @spec start_link(opts :: Keyword.t()) :: Supervisor.on_start()
  def start_link(opts),
    do:
      Supervisor.start_link(__MODULE__, Keyword.take(opts, []),
        name: Keyword.get(opts, :name, __MODULE__)
      )

  @impl Supervisor
  def init(_opts),
    do:
      Supervisor.init(
        [
          Hygeia.SedexExport.SchedulerSupervisor,
          {Highlander, Hygeia.SedexExport.SchedulerCoordinator}
        ],
        strategy: :one_for_all
      )
end
