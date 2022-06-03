defmodule Hygeia.AutoTracingContext.AutoTracing.EmploymentStatus do
  @moduledoc "Employment status"

  use EctoEnum,
    type: :employment_status,
    enums: [:yes, :no, :not_disclosed]

  import HygeiaGettext

  @spec map :: [{String.t(), t}]
  def map, do: Enum.map(__enum_map__(), &{translate(&1), &1})

  @spec translate(type :: t) :: String.t()
  def translate(:yes), do: pgettext("Employment Status", "Yes")
  def translate(:no), do: pgettext("Employment Status", "No")

  def translate(:not_disclosed),
    do: pgettext("Employment Status", "I do not want to give any information about this")
end
