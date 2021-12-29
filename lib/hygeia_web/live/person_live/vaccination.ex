defmodule HygeiaWeb.PersonLive.Vaccination do
  @moduledoc false

  use HygeiaWeb, :surface_live_component

  import Ecto.Changeset

  alias HygeiaWeb.DateInput

  alias Surface.Components.Form.ErrorTag
  alias Surface.Components.Form.Field
  alias Surface.Components.Form.Input.InputContext
  alias Surface.Components.Form.Inputs
  alias Surface.Components.Form.Select
  alias Surface.Components.Form.TextInput

  alias Hygeia.CaseContext.Person.VaccinationShot.VaccineType

  prop preset_date_count, :integer, default: 2
  prop disabled, :boolean, default: false
  prop show_buttons, :boolean, default: true
  prop changeset, :map
  prop person, :map
  prop subject, :any, default: nil

  prop add_event, :event
  prop remove_event, :event

  defp number_format(number, formats)

  defp number_format(number, [{locale, format} | other_formats]) do
    case HygeiaCldr.get_locale() do
      %Cldr.LanguageTag{canonical_locale_name: ^locale} ->
        HygeiaCldr.Number.to_string!(number, format: format)

      _other ->
        number_format(number, other_formats)
    end
  end

  defp number_format(number, [format | other_formats]) do
    HygeiaCldr.Number.to_string!(number, format: format)
  rescue
    Cldr.Rbnf.NoRule -> number_format(number, other_formats)
  end
end
