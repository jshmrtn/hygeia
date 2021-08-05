defmodule Hygeia.AutoTracingContext.AutoTracing.Step do
  @moduledoc "AutoTracing Step"

  use EctoEnum,
    type: :auto_tracing_step,
    enums: [
      :start,
      :address,
      :contact_methods,
      :employer,
      :vaccination,
      :covid_app,
      :clinical,
      :transmission,
      :end
    ]

  import HygeiaGettext

  @spec translate_step(type :: atom) :: String.t()
  def translate_step(:start), do: pgettext("Auto Tracing Step", "Start")
  def translate_step(:address), do: pgettext("Auto Tracing Step", "Address")
  def translate_step(:contact_methods), do: pgettext("Auto Tracing Step", "Contact Methods")
  def translate_step(:employer), do: pgettext("Auto Tracing Step", "Employer")
  def translate_step(:vaccination), do: pgettext("Auto Tracing Step", "Vaccination")
  def translate_step(:covid_app), do: pgettext("Auto Tracing Step", "Covid App")
  def translate_step(:clinical), do: pgettext("Auto Tracing Step", "Clinical")
  def translate_step(:transmission), do: pgettext("Auto Tracing Step", "Transmission")
  def translate_step(:end), do: pgettext("Auto Tracing Step", "Finish")
end
