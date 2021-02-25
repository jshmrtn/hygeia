defmodule HygeiaWeb.Helpers.Phase do
  @moduledoc false

  import HygeiaGettext

  alias Hygeia.CaseContext.Case.Phase

  @spec phase_end_reason_translation(
          phase_end_reason :: Phase.Index.EndReason.t() | Phase.PossibleIndex.EndReason.t()
        ) :: String.t()
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
end
