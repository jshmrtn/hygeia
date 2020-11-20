defmodule HygeiaWeb.Helpers.Clinical do
  @moduledoc false

  import HygeiaGettext

  alias Hygeia.CaseContext.Case.Clinical

  @spec test_reasons :: [{String.t(), Clinical.TestReason.t()}]
  def test_reasons,
    do:
      Enum.map(
        Clinical.TestReason.__enum_map__(),
        &{translate_clinical_test_reason(&1), &1}
      )

  @spec translate_clinical_test_reason(type :: Clinical.TestReason.t()) :: String.t()
  def translate_clinical_test_reason(:symptoms), do: gettext("Symptoms")

  def translate_clinical_test_reason(:outbreak_examination),
    do: gettext("Outbreak examination")

  def translate_clinical_test_reason(:screening), do: gettext("Screening")
  def translate_clinical_test_reason(:work_related), do: gettext("Work related")
  def translate_clinical_test_reason(:quarantine), do: gettext("Quarantine")
  def translate_clinical_test_reason(:app_report), do: gettext("App report")
  def translate_clinical_test_reason(:contact_tracing), do: gettext("Contact tracing")

  @spec symptoms :: [{String.t(), Clinical.Symptom.t()}]
  def symptoms,
    do: Enum.map(Clinical.Symptom.__enum_map__(), &{translate_symptom(&1), &1})

  @spec translate_symptom(type :: Clinical.Symptom.t()) :: String.t()
  def translate_symptom(:fever), do: gettext("Fever")
  def translate_symptom(:cough), do: gettext("Cough")
  def translate_symptom(:loss_of_smell), do: gettext("Loss of smell")
  def translate_symptom(:loss_of_taste), do: gettext("Loss of taste")
  def translate_symptom(:sore_throat), do: gettext("Sore Throat")
  def translate_symptom(:body_aches), do: gettext("Body Aches")
  def translate_symptom(:headaches), do: gettext("Headaches")
  def translate_symptom(:fatigue), do: gettext("Fatigue")
  def translate_symptom(:difficulty_breathing), do: gettext("Diificulty Breathing")
  def translate_symptom(:other), do: gettext("Other")

  @spec test_kinds :: [{String.t(), Clinical.TestKind.t()}]
  def test_kinds,
    do: Enum.map(Clinical.TestKind.__enum_map__(), &{translate_test_kind(&1), &1})

  @spec translate_test_kind(type :: Clinical.TestKind.t()) :: String.t()
  def translate_test_kind(:pcr), do: gettext("PCR")
  def translate_test_kind(:quick), do: gettext("Quick")
  def translate_test_kind(:serology), do: gettext("Serology")

  @spec test_results :: [{String.t(), Clinical.Result.t()}]
  def test_results,
    do: Enum.map(Clinical.Result.__enum_map__(), &{translate_test_result(&1), &1})

  @spec translate_test_result(type :: Clinical.Result.t()) :: String.t()
  def translate_test_result(:positive), do: gettext("Positive")
  def translate_test_result(:negative), do: gettext("Negative")
end
