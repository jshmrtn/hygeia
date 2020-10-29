defmodule HygeiaWeb.Helpers.Case do
  @moduledoc false

  import HygeiaWeb.Gettext

  alias Hygeia.CaseContext.Case
  alias Hygeia.CaseContext.Phase

  @spec case_complexity_translation(complexity :: :complexity) :: :string
  def case_complexity_translation(complexity) do
    case complexity do
      :low -> gettext("Low")
      :medium -> gettext("Medium")
      :high -> gettext("High")
      :extreme -> gettext("Extreme")
      _default -> complexity
    end
  end

  @spec case_complexity_map :: [{:string, :complexity}]
  def case_complexity_map do
    Enum.map(Case.Complexity.__enum_map__(), &{case_complexity_translation(&1), &1})
  end

  @spec case_status_translation(status :: :status) :: :string
  def case_status_translation(status) do
    case status do
      :new -> gettext("New")
      :first_contact -> gettext("First contact")
      :first_check -> gettext("First check")
      :tracing -> gettext("Tracing")
      :care -> gettext("Care")
      :second_check -> gettext("Second check")
      :done -> gettext("Done")
      _default -> status
    end
  end

  @spec case_status_map :: [{:string, :status}]
  def case_status_map do
    Enum.map(Case.Status.__enum_map__(), &{case_status_translation(&1), &1})
  end

  @spec case_display_name(case :: Case.t()) :: String.t()
  def case_display_name(%Case{phases: [%Phase{start: start_date} | _] = phases}) do
    %Phase{end: end_date} = last_phase = List.last(phases)

    "#{case_phase_type_translation(last_phase)} (#{
      Cldr.Interval.to_string!(Date.range(start_date, end_date), HygeiaWeb.Cldr)
    })"
  end

  defp case_phase_type_translation(%Phase{type: :possible_index}), do: gettext("Possible Index")
  defp case_phase_type_translation(%Phase{type: :index}), do: gettext("Index")
end
