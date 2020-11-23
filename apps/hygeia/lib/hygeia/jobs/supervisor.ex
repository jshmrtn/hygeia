defmodule Hygeia.Jobs.Supervisor do
  @moduledoc """
  Jobs Supervisor
  """

  use Supervisor

  alias Hygeia.Jobs.RefreshMaterializedView

  case Mix.env() do
    :test ->
      @jobs []

    _env ->
      @jobs [
        # Refresh Stats Periodically
        {Highlander,
         {RefreshMaterializedView,
          view: :statistics_active_isolation_cases_per_day,
          name: RefreshMaterializedView.ActiveIsolationCasesPerDay}},
        {Highlander,
         {RefreshMaterializedView,
          view: :statistics_cumulative_index_case_end_reasons,
          name: RefreshMaterializedView.CumulativeIndexCaseEndReasons}},
        {Highlander,
         {RefreshMaterializedView,
          view: :statistics_active_quarantine_cases_per_day,
          name: RefreshMaterializedView.ActiveQuarantineCasesPerDay}},
        {Highlander,
         {RefreshMaterializedView,
          view: :statistics_cumulative_possible_index_case_end_reasons,
          name: RefreshMaterializedView.CumulativePossibleIndexCaseEndReasons}},
        {Highlander,
         {RefreshMaterializedView,
          view: :statistics_new_cases_per_day, name: RefreshMaterializedView.NewCasesPerDay}},
        {Highlander,
         {RefreshMaterializedView,
          view: :statistics_active_hospitalization_cases_per_day,
          name: RefreshMaterializedView.ActiveHospitalizationCasesPerDay}}
      ]
  end

  @spec start_link(opts :: Keyword.t()) :: Supervisor.on_start()
  def start_link(opts), do: Supervisor.start_link(__MODULE__, opts, name: __MODULE__)

  @impl Supervisor
  def init(_opts), do: Supervisor.init(@jobs, strategy: :one_for_one, max_restarts: 15)
end
