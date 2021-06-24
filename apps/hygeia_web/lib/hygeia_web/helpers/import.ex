defmodule HygeiaWeb.Helpers.Import do
  @moduledoc false

  import HygeiaGettext

  @spec translate_certainty(type :: atom()) :: String.t()
  def translate_certainty(:input_needed), do: gettext("Input needed")
  def translate_certainty(:uncertain), do: gettext("Uncertain")
  def translate_certainty(:certain), do: gettext("Certain")
end
