defmodule Hygeia.CaseContext.Person.ContactMethod.Type do
  @moduledoc """
  Contact Method Type Enum
  """

  use Hygeia, :model

  use EctoEnum,
    type: :contact_method_type,
    enums: [
      :mobile,
      :landline,
      :email,
      :other
    ]

  import HygeiaGettext

  @spec map :: [{String.t(), t}]
  def map, do: Enum.map(__enum_map__(), &{translate(&1), &1})

  @spec translate(type :: t) :: String.t()
  def translate(:mobile), do: pgettext("Contact Method Type", "Mobile")
  def translate(:landline), do: pgettext("Contact Method Type", "Landline")
  def translate(:email), do: pgettext("Contact Method Type", "Email")
  def translate(:other), do: pgettext("Contact Method Type", "Other")
end
