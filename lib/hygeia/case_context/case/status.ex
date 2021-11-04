defmodule Hygeia.CaseContext.Case.Status do
  @moduledoc """
  Case Status
  """

  use EctoEnum,
    type: :case_status,
    enums: [
      :first_contact,
      :first_contact_unreachable,
      :code_pending,
      :waiting_for_contact_person_list,
      :other_actions_todo,
      :next_contact_agreed,
      :hospitalization,
      :home_resident,
      :done,
      :canceled
    ]

  import HygeiaGettext

  @spec map :: [{String.t(), t}]
  def map, do: Enum.map(__enum_map__(), &{translate(&1), &1})

  @spec translate(event :: t) :: String.t()
  def translate(:first_contact), do: pgettext("Case Status", "First contact")

  def translate(:first_contact_unreachable),
    do: pgettext("Case Status", "First contact, unreachable")

  def translate(:code_pending), do: pgettext("Case Status", "Code Pending")

  def translate(:waiting_for_contact_person_list),
    do: pgettext("Case Status", "Wainting for Contact Person List")

  def translate(:other_actions_todo), do: pgettext("Case Status", "Other Actions To Do")
  def translate(:next_contact_agreed), do: pgettext("Case Status", "Next Contact Agreed")
  def translate(:done), do: pgettext("Case Status", "Done")
  def translate(:hospitalization), do: pgettext("Case Status", "Hospitalization")
  def translate(:home_resident), do: pgettext("Case Status", "Home Resident")
  def translate(:canceled), do: pgettext("Case Status", "Canceled")
end
