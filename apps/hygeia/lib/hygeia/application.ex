defmodule Hygeia.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  alias Hygeia.Jobs.RefreshMaterializedView

  case Mix.env() do
    :test ->
      @jobs []

    _env ->
      @jobs [
        # Refresh Stats Periodically
        {RefreshMaterializedView,
         view: :statistics_active_isolation_cases_per_day,
         name: {:global, RefreshMaterializedView.ActiveIsolationCasesPerDay}},
        {RefreshMaterializedView,
         view: :statistics_cumulative_index_case_end_reasons,
         name: {:global, RefreshMaterializedView.CumulativeIndexCaseEndReasons}},
        {RefreshMaterializedView,
         view: :statistics_active_quarantine_cases_per_day,
         name: {:global, RefreshMaterializedView.ActiveQuarantineCasesPerDay}},
        {RefreshMaterializedView,
         view: :statistics_cumulative_possible_index_case_end_reasons,
         name: {:global, RefreshMaterializedView.CumulativePossibleIndexCaseEndReasons}},
        {RefreshMaterializedView,
         view: :statistics_new_cases_per_day,
         name: {:global, RefreshMaterializedView.NewCasesPerDay}}
      ]
  end

  @impl Application
  @spec start(start_type :: Application.start_type(), start_args :: term()) ::
          {:ok, pid()} | {:ok, pid(), Application.state()} | {:error, reason :: term()}
  def start(_type, _args) do
    {:ok, _} = EctoBootMigration.migrate(:hygeia)

    Supervisor.start_link(
      [
        # Start the Ecto repository
        Hygeia.Repo,
        # Start the PubSub system
        {Phoenix.PubSub, name: Hygeia.PubSub}
        | @jobs
      ],
      strategy: :one_for_one,
      name: Hygeia.Supervisor
    )
  end
end
