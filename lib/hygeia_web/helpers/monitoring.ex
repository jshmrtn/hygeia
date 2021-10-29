defmodule HygeiaWeb.Helpers.Monitoring do
  @moduledoc false

  import HygeiaGettext

  alias Hygeia.CaseContext.Case.Monitoring

  @spec isolation_locations :: [{String.t(), Monitoring.IsolationLocation.t()}]
  def isolation_locations,
    do:
      Enum.map(
        Monitoring.IsolationLocation.__enum_map__(),
        &{translate_isolation_location(&1), &1}
      )

  @spec translate_isolation_location(type :: Monitoring.IsolationLocation.t()) :: String.t()
  def translate_isolation_location(:home), do: gettext("Home")

  def translate_isolation_location(:social_medical_facility),
    do: gettext("Social medical facility")

  def translate_isolation_location(:hospital), do: gettext("Hospital")
  def translate_isolation_location(:hotel), do: gettext("Hotel")
  def translate_isolation_location(:asylum_center), do: gettext("Asylum center")
  def translate_isolation_location(:other), do: gettext("Other")
end
