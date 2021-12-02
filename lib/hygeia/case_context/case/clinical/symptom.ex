defmodule Hygeia.CaseContext.Case.Clinical.Symptom do
  @moduledoc "Symptoms"

  use EctoEnum,
    type: :symptom,
    enums: [
      :fever,
      :cough,
      :sore_throat,
      :loss_of_smell,
      :loss_of_taste,
      :body_aches,
      :headaches,
      :fatigue,
      :difficulty_breathing,
      :muscle_pain,
      :general_weakness,
      :gastrointestinal,
      :skin_rash,
      :other
    ]

  import HygeiaGettext

  @spec map :: [{String.t(), t}]
  def map, do: Enum.map(__enum_map__(), &{translate(&1), &1})

  @spec translate(type :: t) :: String.t()
  def translate(:fever), do: pgettext("Clinical Symptom", "Fever")
  def translate(:cough), do: pgettext("Clinical Symptom", "Cough")
  def translate(:loss_of_smell), do: pgettext("Clinical Symptom", "Loss of smell")
  def translate(:loss_of_taste), do: pgettext("Clinical Symptom", "Loss of taste")
  def translate(:sore_throat), do: pgettext("Clinical Symptom", "Sore Throat")
  def translate(:body_aches), do: pgettext("Clinical Symptom", "Body Aches")
  def translate(:headaches), do: pgettext("Clinical Symptom", "Headaches")
  def translate(:fatigue), do: pgettext("Clinical Symptom", "Fatigue")
  def translate(:difficulty_breathing), do: pgettext("Clinical Symptom", "Diificulty Breathing")
  def translate(:other), do: pgettext("Clinical Symptom", "Other")
  def translate(:muscle_pain), do: pgettext("Clinical Symptom", "Muscle Pain")
  def translate(:general_weakness), do: pgettext("Clinical Symptom", "General Weakness")
  def translate(:gastrointestinal), do: pgettext("Clinical Symptom", "Gastrointestinal")
  def translate(:skin_rash), do: pgettext("Clinical Symptom", "Skin Rash")
end
