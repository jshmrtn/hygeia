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
      :link_propagator,
      :residency_outside_country,
      :no_contact_method,
      :no_reaction
    ]

  import HygeiaGettext

  @spec map :: [{String.t(), t}]
  def map, do: Enum.map(__enum_map__(), &{translate(&1), &1})

  @spec translate(problem :: t) :: String.t()
  def translate(:unmanaged_tenant), do: pgettext("Auto Tracing Problem", "Unmanaged Tenant")
  def translate(:covid_app), do: pgettext("Auto Tracing Problem", "SwissCovid App")

  def translate(:vaccination_failure),
    do: pgettext("Auto Tracing Problem", "Vaccination Failure")

  def translate(:hospitalization), do: pgettext("Auto Tracing Problem", "Hospitalization")
  def translate(:school_related), do: pgettext("Auto Tracing Problem", "School Related")
  def translate(:new_employer), do: pgettext("Auto Tracing Problem", "New Employer")
  def translate(:link_propagator), do: pgettext("Auto Tracing Problem", "Link Propagator")

  def translate(:residency_outside_country),
    do: pgettext("Auto Tracing Problem", "Residency Outside Country")

  def translate(:no_contact_method), do: pgettext("Auto Tracing Problem", "No Contact Method")
  def translate(:no_reaction), do: pgettext("Auto Tracing Problem", "No Reaction")
end
