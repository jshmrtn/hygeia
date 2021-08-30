defmodule Hygeia.AutoTracingContext.AutoTracing.Problem do
  @moduledoc "AutoTracing Problem"

  # TODO: Add other problem cases
  use EctoEnum,
    type: :auto_tracing_problem,
    enums: [
      :unmanaged_tenant,
      :covid_app,
      :vaccination_failure,
      :hospitalization,
      :school_related,
      :new_employer,
      :link_propagator
    ]

  import HygeiaGettext

  @spec translate(problem :: t) :: String.t()
  def translate(:unmanaged_tenant), do: pgettext("Auto Tracing Problem", "Unmanaged Tenant")
  def translate(:covid_app), do: pgettext("Auto Tracing Problem", "Covid App")

  def translate(:vaccination_failure),
    do: pgettext("Auto Tracing Problem", "Vaccination Failure")

  def translate(:hospitalization), do: pgettext("Auto Tracing Problem", "Hospitalization")
  def translate(:school_related), do: pgettext("Auto Tracing Problem", "School Related")
  def translate(:new_employer), do: pgettext("Auto Tracing Problem", "New Employer")
  def translate(:link_propagator), do: pgettext("Auto Tracing Problem", "Link Propagator")
end
