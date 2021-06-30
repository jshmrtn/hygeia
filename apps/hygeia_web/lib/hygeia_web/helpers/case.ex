defmodule HygeiaWeb.Helpers.Case do
  @moduledoc false

  import HygeiaGettext

  alias Hygeia.CaseContext.Case
  alias Hygeia.CaseContext.Case.Phase
  alias Hygeia.CaseContext.Case.Phase.Index
  alias Hygeia.CaseContext.Case.Phase.PossibleIndex

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
    do: "#{PossibleIndex.Type.translate(:other)} / #{type_other}"

  def case_phase_type_translation(%PossibleIndex{type: type}),
    do: PossibleIndex.Type.translate(type)

  def case_phase_type_translation(%Index{}), do: gettext("Index")

  def case_phase_type_translation(%Phase{details: details}),
    do: case_phase_type_translation(details)

  def case_phase_type_translation(%Ecto.Changeset{} = changeset),
    do: case_phase_type_translation(Ecto.Changeset.apply_changes(changeset))
end
