defmodule HygeiaWeb.PersonLive.Vaccination do
  @moduledoc false

  use HygeiaWeb, :surface_live_component

  import Ecto.Changeset

  alias Surface.Components.Form.DateInput
  alias Surface.Components.Form.ErrorTag
  alias Surface.Components.Form.Field
  alias Surface.Components.Form.Input.InputContext
  alias Surface.Components.Form.TextInput

  prop preset_date_count, :integer, default: 2
  prop disabled, :boolean, default: false
  prop show_buttons, :boolean, default: true
  prop changeset, :map
  prop person, :map

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
