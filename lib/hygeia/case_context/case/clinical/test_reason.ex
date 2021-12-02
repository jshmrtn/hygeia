defmodule Hygeia.CaseContext.Case.Clinical.TestReason do
  @moduledoc "Test Reason"

  use EctoEnum,
    type: :test_reason,
    enums: [
      :symptoms,
      :outbreak_examination,
      :screening,
      :work_related,
      :quarantine,
      :app_report,
      :convenience,
      :contact_tracing,
      :quarantine_end
    ]

  import HygeiaGettext

  @spec map :: [{String.t(), t}]
  def map, do: Enum.map(__enum_map__(), &{translate(&1), &1})

  @spec translate(type :: t) :: String.t()
  def translate(:symptoms), do: pgettext("Test Reason", "Symptoms")
  def translate(:outbreak_examination), do: pgettext("Test Reason", "Outbreak examination")
  def translate(:screening), do: pgettext("Test Reason", "Screening")
  def translate(:work_related), do: pgettext("Test Reason", "Work related")
  def translate(:quarantine), do: pgettext("Test Reason", "Quarantine")
  def translate(:app_report), do: pgettext("Test Reason", "App report")
  def translate(:contact_tracing), do: pgettext("Test Reason", "Contact tracing")
  def translate(:convenience), do: pgettext("Test Reason", "Convenience")
  def translate(:quarantine_end), do: pgettext("Test Reason", "Quarantine End")
end
