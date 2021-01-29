defmodule HygeiaWeb.Helpers.Person do
  @moduledoc false

  import HygeiaGettext

  alias Hygeia.CaseContext.Person

  @spec translate_person_sex(sex :: Person.Sex.t()) :: String.t()
  def translate_person_sex(:male), do: pgettext("Sex", "Male")
  def translate_person_sex(:female), do: pgettext("Sex", "Female")
  def translate_person_sex(:other), do: pgettext("Sex", "Other")

  @spec person_sex_map :: [{String.t(), Person.Sex.t()}]
  def person_sex_map do
    Enum.map(Person.Sex.__enum_map__(), &{translate_person_sex(&1), &1})
  end
end
