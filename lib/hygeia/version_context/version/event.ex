defmodule Hygeia.VersionContext.Version.Event do
  @moduledoc """
  Event Type
  """

  use EctoEnum, type: :versioning_event, enums: [:insert, :update, :delete]

  import HygeiaGettext

  @spec translate(event :: t) :: String.t()
  def translate(:update), do: pgettext("versioning_event", "update")
  def translate(:insert), do: pgettext("versioning_event", "insert")
  def translate(:delete), do: pgettext("versioning_event", "delete")
end
