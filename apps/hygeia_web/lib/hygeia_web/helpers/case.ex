defmodule HygeiaWeb.Helpers.Case do
  @moduledoc false

  import HygeiaGettext

  alias Hygeia.CaseContext.Case
  alias Hygeia.CaseContext.Case.Phase
  alias Hygeia.CaseContext.Case.Phase.Index
  alias Hygeia.CaseContext.Case.Phase.PossibleIndex

  @spec case_complexity_translation(complexity :: Case.Complexity.t()) :: String.t()
  def case_complexity_translation(:low), do: gettext("Low")
  def case_complexity_translation(:medium), do: gettext("Medium")
  def case_complexity_translation(:high), do: gettext("High")
  def case_complexity_translation(:extreme), do: gettext("Extreme")

  @spec case_complexity_map :: [{String.t(), Case.Complexity.t()}]
  def case_complexity_map do
    Enum.map(Case.Complexity.__enum_map__(), &{case_complexity_translation(&1), &1})
  end

  @spec case_status_translation(status :: Case.Status.t()) :: String.t()
  def case_status_translation(:new), do: gettext("New")
  def case_status_translation(:first_contact), do: gettext("First contact")
  def case_status_translation(:first_check), do: gettext("First check")
  def case_status_translation(:tracing), do: gettext("Tracing")
  def case_status_translation(:care), do: gettext("Care")
  def case_status_translation(:second_check), do: gettext("Second check")
  def case_status_translation(:done), do: gettext("Done")

  @spec case_status_map :: [{String.t(), Case.Status.t()}]
  def case_status_map do
    Enum.map(Case.Status.__enum_map__(), &{case_status_translation(&1), &1})
  end

  @spec case_phase_index_end_reason_map :: [{String.t(), Index.EndReason.t()}]
  def case_phase_index_end_reason_map do
    Enum.map(
      Index.EndReason.__enum_map__(),
      &{case_phase_index_end_reason_translation(&1), &1}
    )
  end

  @spec case_phase_index_end_reason_translation(Index.EndReason.t()) :: String.t()
  def case_phase_index_end_reason_translation(:healed), do: gettext("Healed")
  def case_phase_index_end_reason_translation(:death), do: gettext("Death")
  def case_phase_index_end_reason_translation(:no_follow_up), do: gettext("No Follow Up")

  @spec case_phase_possible_index_end_reason_map :: [
          {String.t(), PossibleIndex.EndReason.t()}
        ]
  def case_phase_possible_index_end_reason_map do
    Enum.map(
      PossibleIndex.EndReason.__enum_map__(),
      &{case_phase_possible_index_end_reason_translation(&1), &1}
    )
  end

  @spec case_phase_possible_index_end_reason_translation(PossibleIndex.EndReason.t()) ::
          String.t()
  def case_phase_possible_index_end_reason_translation(:asymptomatic), do: gettext("Asymptomatic")

  def case_phase_possible_index_end_reason_translation(:converted_to_index),
    do: gettext("Converted to Index")

  def case_phase_possible_index_end_reason_translation(:no_follow_up), do: gettext("No Follow Up")
  def case_phase_possible_index_end_reason_translation(:other), do: gettext("Other")

  @spec case_phase_possible_index_type_map :: [
          {String.t(), PossibleIndex.Type.t()}
        ]
  def case_phase_possible_index_type_map do
    Enum.map(
      PossibleIndex.Type.__enum_map__(),
      &{case_phase_possible_index_type_translation(&1), &1}
    )
  end

  @spec case_phase_possible_index_type_translation(PossibleIndex.Type.t()) :: String.t()
  def case_phase_possible_index_type_translation(:contact_person), do: gettext("Contact Person")
  def case_phase_possible_index_type_translation(:travel), do: gettext("Travel")

  @spec case_display_name(case :: Case.t()) :: String.t()
  def case_display_name(
        %Case{
          phases: [%Phase{} | _] = phases
        } = case
      ) do
    last_phase = List.last(phases)

    gettext("%{phase_type} (%{date})",
      phase_type: case_phase_type_translation(last_phase),
      date: case_display_date(case)
    )
  end

  @spec case_display_date(case :: Case.t()) :: String.t()
  def case_display_date(%Case{
        phases: [%Phase{start: start_date} | _] = phases,
        inserted_at: inserted_at
      }) do
    %Phase{end: end_date} = List.last(phases)

    case {start_date, end_date} do
      {nil, _end_date} ->
        gettext("Created at %{created_at}",
          created_at: Cldr.DateTime.to_string!(inserted_at, HygeiaCldr)
        )

      {_start_date, nil} ->
        gettext("Created at %{created_at}",
          created_at: Cldr.DateTime.to_string!(inserted_at, HygeiaCldr)
        )

      {start_date, end_date} ->
        Cldr.Interval.to_string!(Date.range(start_date, end_date), HygeiaCldr)
    end
  end

  @spec case_phase_type_translation(phase :: Phase.t()) :: String.t()
  def case_phase_type_translation(%Phase{details: %PossibleIndex{type: :travel}}),
    do: gettext("Travel")

  def case_phase_type_translation(%Phase{details: %PossibleIndex{type: :contact_person}}),
    do: gettext("Contact Person")

  def case_phase_type_translation(%Phase{details: %Index{}}), do: gettext("Index")
end
