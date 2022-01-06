defmodule Hygeia.CaseContext.Case.Phase do
  @moduledoc """
  Model for Phase Schema
  """

  use Hygeia, :model

  import HygeiaGettext

  alias Hygeia.CaseContext.Case.Phase.Index
  alias Hygeia.CaseContext.Case.Phase.PossibleIndex
  alias Hygeia.CaseContext.Case.Phase.Type, as: PhaseType
  alias Hygeia.CaseContext.PrematureRelease.DisabledReason
  alias Hygeia.TenantContext.Tenant

  @type empty :: %__MODULE__{
          quarantine_order: boolean() | nil,
          order_date: DateTime.t() | nil,
          type: PhaseType.t() | nil,
          start: Date.t() | nil,
          end: Date.t() | nil,
          details: Index.t() | PossibleIndex.t() | nil,
          inserted_at: DateTime.t() | nil,
          premature_release_permission: boolean() | nil,
          premature_release_disabled_reason: DisabledReason.t() | nil,
          premature_release_disabled_reason_other: String.t() | nil
        }

  @type t ::
          %__MODULE__{
            quarantine_order: true,
            order_date: DateTime.t(),
            type: PhaseType.t() | nil,
            start: Date.t(),
            end: Date.t(),
            details: Index.t() | PossibleIndex.t(),
            inserted_at: DateTime.t(),
            premature_release_permission: boolean() | nil,
            premature_release_disabled_reason: DisabledReason.t() | nil,
            premature_release_disabled_reason_other: String.t() | nil
          }
          | %__MODULE__{
              quarantine_order: false | nil,
              order_date: nil,
              start: nil,
              end: nil,
              details: Index.t() | PossibleIndex.t(),
              inserted_at: DateTime.t(),
              premature_release_permission: boolean() | nil,
              premature_release_disabled_reason: DisabledReason.t() | nil,
              premature_release_disabled_reason_other: String.t() | nil
            }

  @derive {Phoenix.Param, key: :uuid}

  embedded_schema do
    field :quarantine_order, :boolean
    field :order_date, :utc_datetime_usec
    field :start, :date
    field :end, :date
    field :type, PhaseType, virtual: true
    field :send_automated_close_email, :boolean, default: true
    field :automated_close_email_sent, :utc_datetime_usec

    field :premature_release_permission, :boolean, default: true
    field :premature_release_disabled_reason, DisabledReason
    field :premature_release_disabled_reason_other, :string

    field :details, PolymorphicEmbed,
      types: [
        index: Index,
        possible_index: PossibleIndex
      ],
      on_replace: :update

    timestamps(updated_at: false)
  end

  @doc false
  @spec changeset(
          phase :: t | empty | Changeset.t(t | empty),
          attrs :: Hygeia.ecto_changeset_params()
        ) :: Changeset.t()
  def changeset(phase, attrs) do
    phase
    |> cast(attrs, [
      :quarantine_order,
      :order_date,
      :start,
      :end,
      :type,
      :send_automated_close_email,
      :automated_close_email_sent,
      :premature_release_permission,
      :premature_release_disabled_reason,
      :premature_release_disabled_reason_other
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
    |> set_order_date()
    |> validate_premature_release_permission()
    |> validate_premature_release_disabled_reason_other()
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

  defp set_order_date(changeset) do
    case fetch_change(changeset, :quarantine_order) do
      {:ok, true} -> put_change(changeset, :order_date, DateTime.utc_now())
      {:ok, false} -> put_change(changeset, :order_date, nil)
      {:ok, nil} -> put_change(changeset, :order_date, nil)
      :error -> changeset
    end
  end

  defp validate_premature_release_permission(changeset) do
    changeset
    |> fetch_field!(:premature_release_permission)
    |> case do
      true ->
        changeset
        |> put_change(:premature_release_disabled_reason, nil)
        |> put_change(:premature_release_disabled_reason_other, nil)

      _defined ->
        changeset
        |> put_change(:premature_release_permission, false)
        |> validate_required([:premature_release_disabled_reason])
    end
  end

  defp validate_premature_release_disabled_reason_other(changeset) do
    changeset
    |> fetch_field!(:premature_release_disabled_reason)
    |> case do
      :other ->
        validate_required(changeset, [:premature_release_disabled_reason_other])

      _defined ->
        put_change(changeset, :premature_release_disabled_reason_other, nil)
    end
  end

  @spec can_generate_pdf_confirmation?(phase :: t, tenant :: Tenant.t()) :: boolean
  def can_generate_pdf_confirmation?(phase, tenant)
  def can_generate_pdf_confirmation?(%__MODULE__{quarantine_order: false}, _tenant), do: false
  def can_generate_pdf_confirmation?(%__MODULE__{start: nil}, _tenant), do: false
  def can_generate_pdf_confirmation?(%__MODULE__{end: nil}, _tenant), do: false

  def can_generate_pdf_confirmation?(%__MODULE__{details: %PossibleIndex{type: type}}, _tenant)
      when type != :contact_person,
      do: false

  def can_generate_pdf_confirmation?(_phase, %Tenant{template_variation: nil}), do: false
  def can_generate_pdf_confirmation?(_phase, _tenant), do: true

  @spec can_generate_pdf_end_confirmation?(phase :: t, tenant :: Tenant.t()) :: boolean
  def can_generate_pdf_end_confirmation?(phase, tenant),
    do:
      can_generate_pdf_confirmation?(phase, tenant) and
        Date.compare(Date.add(Date.utc_today(), 1), phase.end) in [:gt, :eq]
end
