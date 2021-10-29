defmodule Hygeia.CaseContext.Person.Sex do
  @moduledoc """
  Person Sex Enum
  """

  use Hygeia, :model

  use EctoEnum,
    type: :sex,
    enums: [
      :male,
      :female,
      :other
    ]

  import HygeiaGettext

  @spec map :: [{String.t(), t}]
  def map, do: Enum.map(__enum_map__(), &{translate(&1), &1})

  @spec translate(type :: t) :: String.t()
  def translate(:male), do: pgettext("Sex", "Male")
  def translate(:female), do: pgettext("Sex", "Female")
  def translate(:other), do: pgettext("Sex", "Other")
end
