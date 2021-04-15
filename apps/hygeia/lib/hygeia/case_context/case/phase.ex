defmodule Hygeia.CaseContext.Case.Phase do
  @moduledoc """
  Model for Phase Schema
  """

  use Hygeia, :model

  import HygeiaGettext

  alias Hygeia.CaseContext.Case.Phase.Index
  alias Hygeia.CaseContext.Case.Phase.PossibleIndex

  @type empty :: %__MODULE__{
          quarantine_order: boolean() | nil,
          start: Date.t() | nil,
          end: Date.t() | nil,
          details: Index.t() | PossibleIndex.t() | nil
        }

  @type t ::
          %__MODULE__{
            quarantine_order: true,
            start: Date.t(),
            end: Date.t(),
            details: Index.t() | PossibleIndex.t()
          }
          | %__MODULE__{
              quarantine_order: false | nil,
              start: nil,
              end: nil,
              details: Index.t() | PossibleIndex.t()
            }

  @derive {Phoenix.Param, key: :uuid}

  embedded_schema do
    field :quarantine_order, :boolean
    field :start, :date
    field :end, :date
    field :send_automated_close_email, :boolean, default: true
    field :automated_close_email_sent, :utc_datetime_usec

    field :details, PolymorphicEmbed,
      types: [
        index: Index,
        possible_index: PossibleIndex
      ],
      on_replace: :update
  end

  @doc false
  @spec changeset(phase :: t | empty, attrs :: Hygeia.ecto_changeset_params()) :: Changeset.t()
  def changeset(phase, attrs) do
    phase
    |> cast(attrs, [
      :quarantine_order,
      :start,
      :end,
      :send_automated_close_email,
      :automated_close_email_sent
    ])
    |> cast_polymorphic_embed(:details)
    |> validate_required([:details])
    |> validate_date_recent(:start)
    |> validate_date_recent(:end)
    |> validate_date_relative(
      :start,
      [:lt, :eq],
      :end,
      dgettext("errors", "start must be before end")
    )
    |> validate_date_relative(
      :end,
      [:gt, :eq],
      :start,
      dgettext("errors", "end must be after start")
    )
    |> validate_quarantine_order()
  end

  defp validate_date_relative(changeset, field, cmp_equality, cmp_field, message) do
    case get_field(changeset, cmp_field) do
      nil ->
        changeset

      cmp_value ->
        validate_change(changeset, field, fn
          ^field, nil ->
            []

          ^field, value ->
            if Date.compare(value, cmp_value) in cmp_equality do
              []
            else
              [{field, message}]
            end
        end)
    end
  end

  defp validate_date_recent(changeset, field) do
    validate_change(changeset, field, fn ^field, value ->
      if Kernel.abs(Date.diff(Date.utc_today(), value)) > 356 do
        [{field, dgettext("errors", "date is to far away from today")}]
      else
        []
      end
    end)
  end

  defp validate_quarantine_order(changeset) do
    if get_field(changeset, :quarantine_order) == true do
      validate_required(changeset, [:start, :end])
    else
      changeset
      |> put_change(:start, nil)
      |> put_change(:end, nil)
    end
  end
end
