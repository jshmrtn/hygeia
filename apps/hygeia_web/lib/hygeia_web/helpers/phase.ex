defmodule HygeiaWeb.Helpers.Phase do
  @moduledoc false

  import HygeiaGettext

  alias Hygeia.CaseContext.Case.Phase

  @spec phase_type_translation(phase_type :: :phase_type) :: :string
  def phase_type_translation(phase_type) do
    case phase_type do
      :index -> gettext("Index")
      :possible_index -> gettext("Possible index")
      _default -> phase_type
    end
  end

  @spec phase_end_reason_translation(phase_end_reason :: :isolation_location) :: :string
  def phase_end_reason_translation(phase_end_reason) do
    case phase_end_reason do
      :healed -> gettext("Healed")
      :death -> gettext("Death")
      :no_follow_up -> gettext("No follow up")
      :asymptomatic -> gettext("Asymptomatic")
      :converted_to_index -> gettext("Converted to Index")
      :other -> gettext("Other")
      _default -> phase_end_reason
    end
  end

  @spec phase_end_reason_map :: [{String.t(), atom}]
  def phase_end_reason_map do
    Enum.map(Phase.EndReason.__enum_map__(), &{phase_end_reason_translation(&1), &1})
  end
end
