defmodule HygeiaPdfConfirmation.Helpers.ConfirmationDates do
  @moduledoc """
  Helpers for Confirmation Dates
  """

  alias Hygeia.CaseContext.Case

  @spec isolation_start_date(case :: Case.t(), phase_start :: Date.t()) :: Date.t()
  @doc deprecated: "Use #{Case}.earliest_self_service_phase_start_date/2 instead"
  def isolation_start_date(case, _phase_start) do
    {_status, date} = Case.earliest_self_service_phase_start_date(case, Case.Phase.Index)
    date
  end
end
