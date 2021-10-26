defmodule Hygeia.Jobs.Supervisor do
  @moduledoc """
  Jobs Supervisor
  """

  use Supervisor

  alias Hygeia.Jobs.RefreshMaterializedView
  alias HygeiaIam.ServiceUserToken

  case Mix.env() do
    :test ->
      @jobs []

    _env ->
      @jobs [
        # Task Supervisor
        {Task.Supervisor, name: Hygeia.Jobs.TaskSupervisor},

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
          name: RefreshMaterializedView.ActiveHospitalizationCasesPerDay}},
        {Highlander,
         {RefreshMaterializedView,
          view: :statistics_active_complexity_cases_per_day,
          name: RefreshMaterializedView.ActiveComplexityCasesPerDay}},
        {Highlander,
         {RefreshMaterializedView,
          view: :statistics_active_infection_place_cases_per_day,
          name: RefreshMaterializedView.ActiveInfectionPlaceCasesPerDay}},
        {Highlander,
         {RefreshMaterializedView,
          view: :statistics_transmission_country_cases_per_day,
          name: RefreshMaterializedView.TransmissionCountryCasesPerDay}},
        {Highlander,
         {RefreshMaterializedView,
          view: :statistics_active_cases_per_day_and_organisation,
          name: RefreshMaterializedView.ActiveCasesPerDayAndOrganisation}},
        {Highlander,
         {RefreshMaterializedView,
          view: :statistics_new_registered_cases_per_day,
          name: RefreshMaterializedView.NewRegisteredCasesPerDay}},

        # Message Triggers
        {Highlander, Hygeia.Jobs.SendCaseClosedEmail},

        # Email Spooling
        {Highlander, Hygeia.Jobs.SendEmails},

        # SMS Spooling
        {Highlander, Hygeia.Jobs.SendSMS},

        # Notification Emails
        {Highlander, Hygeia.Jobs.NotificationReminder},

        # User Sync
        {ServiceUserToken, user: :user_sync, name: Module.concat(ServiceUserToken, UserSync)},
        {Highlander,
         {Hygeia.Jobs.UserSync,
          user_sync_token_server_name: Module.concat(ServiceUserToken, UserSync)}},

        # Persist Viewer Log
        Hygeia.Jobs.ViewerLogPersistence.Supervisor,

        # Detect No Reaction Cases
        Hygeia.Jobs.DetectNoReactionCases
      ]
  end

  @spec start_link(opts :: Keyword.t()) :: Supervisor.on_start()
  def start_link(opts), do: Supervisor.start_link(__MODULE__, opts, name: __MODULE__)

  @impl Supervisor
  def init(_opts),
    do: Supervisor.init(@jobs, strategy: :one_for_one, max_restarts: length(@jobs) * 2)
end
