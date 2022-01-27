defmodule HygeiaWeb.Helpers.Import do
  @moduledoc false

  import HygeiaGettext

  @spec translate_certainty(type :: atom()) :: String.t()
  def translate_certainty(:input_needed), do: pgettext("Import Helpers", "Input needed")
  def translate_certainty(:uncertain), do: pgettext("Import Helpers", "Uncertain")
  def translate_certainty(:certain), do: pgettext("Import Helpers", "Certain")

  @spec translate_invalid_changes(type :: atom()) :: String.t()
  def translate_invalid_changes(:email), do: pgettext("Import Helpers", "Email")
  def translate_invalid_changes(:subdivision), do: pgettext("Import Helpers", "Subdivision")
end
