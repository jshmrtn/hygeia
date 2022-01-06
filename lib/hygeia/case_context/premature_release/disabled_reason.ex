defmodule Hygeia.CaseContext.PrematureRelease.DisabledReason do
  @moduledoc """
  Premature Release Disabled Reason
  """

  use Hygeia, :model

  use EctoEnum,
    type: :premature_release_disabled_reason,
    enums: [
      :virus_variant,
      :other
    ]

  import HygeiaGettext

  @spec map :: [{String.t(), t}]
  def map, do: Enum.map(__enum_map__(), &{translate(&1), &1})

  @spec translate(event :: t) :: String.t()
  def translate(:virus_variant),
    do: pgettext("Premature Release Disabled Reason", "Virus variant")

  def translate(:other), do: pgettext("Premature Release Disabled Reason", "Other")
end
