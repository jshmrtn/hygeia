defmodule HygeiaPdfConfirmation.Helpers.ConfirmationDates do
  @moduledoc """
  Helpers for Confirmation Dates
  """

  alias Hygeia.CaseContext.Case

  @spec isolation_start_date(case :: Case.t(), phase_start :: Date.t()) :: start_date :: Date.t()
  def isolation_start_date(case, phase_start) do
    clinical = if is_nil(case.clinical), do: nil, else: Map.from_struct(case.clinical)

    Enum.find(
      [clinical[:symptom_start], clinical[:test], clinical[:laboratory_report], phase_start],
      nil,
      &(not is_nil(&1))
    )
  end
end
