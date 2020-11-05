defmodule HygeiaWeb.Helpers.Search do
  @moduledoc false

  import HygeiaGettext

  @spec translate_group(type :: atom()) :: String.t()
  def translate_group(:person), do: gettext("Person")
  def translate_group(:case), do: gettext("Case")
  def translate_group(:organisation), do: gettext("Organization")
  def translate_group(:user), do: gettext("User")
end
