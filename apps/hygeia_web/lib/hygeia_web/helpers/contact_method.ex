defmodule HygeiaWeb.Helpers.ContactMethod do
  @moduledoc false

  import HygeiaGettext

  alias Hygeia.CaseContext.Case.ContactMethod

  @spec contact_method_options :: [{String.t(), ContactMethod.Type.t()}]
  def contact_method_options,
    do: Enum.map(ContactMethod.Type.__enum_map__(), &{translate_contact_method_type(&1), &1})

  @spec translate_contact_method_type(type :: ContactMethod.Type.t()) :: String.t()
  def translate_contact_method_type(:mobile), do: gettext("Mobile")
  def translate_contact_method_type(:landline), do: gettext("Landline")
  def translate_contact_method_type(:email), do: gettext("Email")
  def translate_contact_method_type(:other), do: gettext("Other")
end
