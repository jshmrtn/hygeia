defmodule Hygeia.AutoTracingContext.AutoTracing.Step do
  @moduledoc "AutoTracing Step"

  use EctoEnum,
    type: :auto_tracing_step,
    enums: [
      :start,
      :address,
      :contact_methods,
      :visits,
      :employer,
      :vaccination,
      :covid_app,
      :clinical,
      :travel,
      :transmission,
      :contact_persons,
      :end
    ]

  import HygeiaGettext

  @spec map :: [{String.t(), t}]
  def map, do: Enum.map(__enum_map__(), &{translate(&1), &1})

  @spec translate(type :: t) :: String.t()
  def translate(:start), do: pgettext("Auto Tracing Step", "Start")
  def translate(:address), do: pgettext("Auto Tracing Step", "Address")
  def translate(:contact_methods), do: pgettext("Auto Tracing Step", "Contact Methods")
  def translate(:visits), do: pgettext("Auto Tracing Step", "Visits")
  def translate(:employer), do: pgettext("Auto Tracing Step", "Employer")
  def translate(:vaccination), do: pgettext("Auto Tracing Step", "Vaccination")
  def translate(:covid_app), do: pgettext("Auto Tracing Step", "SwissCovid App")
  def translate(:clinical), do: pgettext("Auto Tracing Step", "Clinical")
  def translate(:travel), do: pgettext("Auto Tracing Step", "Travel")
  def translate(:transmission), do: pgettext("Auto Tracing Step", "Transmission")
  def translate(:contact_persons), do: pgettext("Auto Tracing Step", "Contact Persons")
  def translate(:end), do: pgettext("Auto Tracing Step", "Finish")

  @spec get_next_step(step :: t) :: t | nil
  def get_next_step(step), do: get_relative_step(step, &(&1 + 1))

  @spec get_previous_step(step :: t) :: t | nil
  def get_previous_step(step), do: get_relative_step(step, &(&1 - 1))

  defp get_relative_step(step, index_fn) do
    steps = publicly_available_steps()

    case Enum.find_index(steps, &(&1 == step)) do
      nil -> nil
      current_index -> Enum.at(steps, index_fn.(current_index))
    end
  end

  @spec publicly_available_steps :: [t()]
  def publicly_available_steps do
    if Application.fetch_env!(:hygeia, :quarantine_enabled) do
      __enum_map__()
    else
      __enum_map__() -- [:contact_persons]
    end
  end

  @spec completed_steps :: [t()]
  def completed_steps, do: publicly_available_steps() |> Enum.reverse() |> Enum.slice(0, 2)
end
