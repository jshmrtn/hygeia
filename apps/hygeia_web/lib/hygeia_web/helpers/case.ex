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
  def case_status_translation(:first_contact), do: gettext("First contact")

  def case_status_translation(:first_contact_unreachable),
    do: gettext("First contact, unreachable")

  def case_status_translation(:code_pending), do: gettext("Code Pending")

  def case_status_translation(:waiting_for_contact_person_list),
    do: gettext("Wainting for Contact Person List")

  def case_status_translation(:other_actions_todo),
    do: pgettext("case_status", "Other Actions To Do")

  def case_status_translation(:next_contact_agreed),
    do: pgettext("case_status", "Next Contact Agreed")

  def case_status_translation(:done), do: pgettext("case_status", "Done")
  def case_status_translation(:hospitalization), do: pgettext("case_status", "Hospitalization")
  def case_status_translation(:home_resident), do: pgettext("case_status", "Home Resident")

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
  def case_phase_index_end_reason_translation(:healed), do: pgettext("Index Type", "Healed")
  def case_phase_index_end_reason_translation(:death), do: pgettext("Index Type", "Death")

  def case_phase_index_end_reason_translation(:no_follow_up),
    do: pgettext("Index Type", "No Follow Up")

  def case_phase_index_end_reason_translation(:other), do: pgettext("Index Type", "Other")

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
  def case_phase_possible_index_end_reason_translation(:asymptomatic),
    do: pgettext("Possible Index End Reason", "Asymptomatic")

  def case_phase_possible_index_end_reason_translation(:converted_to_index),
    do: gettext("Converted to Index")

  def case_phase_possible_index_end_reason_translation(:no_follow_up),
    do: pgettext("Possible Index End Reason", "No Follow Up")

  def case_phase_possible_index_end_reason_translation(:negative_test),
    do: pgettext("Possible Index End Reason", "Negative Test")

  def case_phase_possible_index_end_reason_translation(:other),
    do: pgettext("Possible Index End Reason", "Other")

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
  def case_phase_possible_index_type_translation(:contact_person),
    do: pgettext("Possible Index Type", "Contact Person")

  def case_phase_possible_index_type_translation(:travel),
    do: pgettext("Possible Index Type", "Travel")

  def case_phase_possible_index_type_translation(:outbreak),
    do: pgettext("Possible Index Type", "Outbreak Examination")

  def case_phase_possible_index_type_translation(:covid_app),
    do: pgettext("Possible Index Type", "CovidApp Alert")

  def case_phase_possible_index_type_translation(:other),
    do: pgettext("Possible Index Type", "Other")

  @spec case_display_name(case :: Case.t()) :: String.t()
  def case_display_name(case), do: "#{case_display_type(case)} (#{case_display_date(case)})"

  @spec case_display_type(case :: Case.t()) :: String.t()
  def case_display_type(%Case{phases: phases} = _case),
    do:
      phases
      |> Enum.map(&case_phase_type_translation/1)
      |> HygeiaCldr.List.to_string!(format: :unit_short)

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
        range =
          case Date.compare(start_date, end_date) do
            :gt -> Date.range(end_date, start_date)
            other when other in [:lt, :eq] -> Date.range(start_date, end_date)
          end

        Cldr.Interval.to_string!(range, HygeiaCldr)
    end
  end

  @spec case_phase_type_translation(
          phase ::
            Phase.t()
            | Index.t()
            | PossibleIndex.t()
            | Ecto.Changeset.t(Phase.t() | Index.t() | PossibleIndex.t())
        ) :: String.t()
  def case_phase_type_translation(%PossibleIndex{type: :other, type_other: type_other}),
    do: "#{case_phase_possible_index_type_translation(:other)} / #{type_other}"

  def case_phase_type_translation(%PossibleIndex{type: type}),
    do: case_phase_possible_index_type_translation(type)

  def case_phase_type_translation(%Index{}), do: gettext("Index")

  def case_phase_type_translation(%Phase{details: details}),
    do: case_phase_type_translation(details)

  def case_phase_type_translation(%Ecto.Changeset{} = changeset),
    do: case_phase_type_translation(Ecto.Changeset.apply_changes(changeset))
end
