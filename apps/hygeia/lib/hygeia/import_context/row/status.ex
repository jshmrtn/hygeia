defmodule Hygeia.ImportContext.Row.Status do
  @moduledoc """
  Status of Import Row
  """

  use EctoEnum, type: :case_import_status, enums: [:pending, :discarded, :resolved]

  import HygeiaGettext

  @spec map :: [{String.t(), t}]
  def map, do: Enum.map(__enum_map__(), &{translate(&1), &1})

  @spec translate(type :: t) :: String.t()
  def translate(:pending), do: pgettext("Case Import Row Status", "Pending")
  def translate(:discarded), do: pgettext("Case Import Row Status", "Discarded")
  def translate(:resolved), do: pgettext("Case Import Row Status", "Resolved")
end
