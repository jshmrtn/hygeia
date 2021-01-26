defmodule Hygeia.SedexExport.SchedulerSupervisor do
  @moduledoc """
  Supervisor for Sedex Export Schedulers
  """

  use DynamicSupervisor

  @spec start_link(opts :: Keyword.t()) :: Supervisor.on_start()
  def start_link(opts),
    do:
      DynamicSupervisor.start_link(__MODULE__, Keyword.take(opts, []),
        name: Keyword.get(opts, :name, __MODULE__)
      )

  @impl DynamicSupervisor
  def init(_opts), do: DynamicSupervisor.init(strategy: :one_for_one)
end
