defmodule Hygeia.CaseContext.Case.Clinical do
  @moduledoc """
  Model for Clinical Schema
  """

  use Hygeia, :model

  import EctoEnum

  alias Hygeia.CaseContext.Entity

  defenum TestReason, :test_reason, [
    "symptoms",
    "outbreak_examination",
    "screening",
    "work_related",
    "quarantine",
    "app_report",
    "convenience",
    "contact_tracing",
    "quarantine_end"
  ]

  defenum Symptom, :symptom, [
    "fever",
    "cough",
    "sore_throat",
    "loss_of_smell",
    "loss_of_taste",
    "body_aches",
    "headaches",
    "fatigue",
    "difficulty_breathing",
    "muscle_pain",
    "general_weakness",
    "gastrointestinal",
    "skin_rash",
    "other"
  ]

  defenum TestKind, :test_kind, ["pcr", "serology", "quick", "antigen_quick", "antibody"]

  defenum Result, :test_result, ["positive", "negative"]

  @type empty :: %__MODULE__{
          reasons_for_test: [TestReason.t()] | nil,
          has_symptoms: boolean() | nil,
          symptoms: [Symptom.t()] | nil,
          test: Date.t() | nil,
          laboratory_report: Date.t() | nil,
          test_kind: TestKind.t() | nil,
          result: Result.t() | nil,
          sponsor: Entity.t() | nil,
          reporting_unit: Entity.t() | nil,
          symptom_start: Date.t() | nil
        }

  @type t :: %__MODULE__{
          reasons_for_test: [TestReason.t()],
          has_symptoms: boolean() | nil,
          symptoms: [Symptom.t()],
          test: Date.t() | nil,
          laboratory_report: Date.t() | nil,
          test_kind: TestKind.t() | nil,
          result: Result.t() | nil,
          sponsor: Entity.t() | nil,
          reporting_unit: Entity.t() | nil,
          symptom_start: Date.t() | nil
        }

  embedded_schema do
    field :reasons_for_test, {:array, TestReason}
    field :has_symptoms, :boolean
    field :symptoms, {:array, Symptom}
    field :test, :date
    field :laboratory_report, :date
    field :test_kind, TestKind
    field :result, Result
    field :symptom_start, :date

    embeds_one :sponsor, Entity, on_replace: :update
    embeds_one :reporting_unit, Entity, on_replace: :update
  end

  @doc false
  @spec changeset(clinical :: t | empty, attrs :: Hygeia.ecto_changeset_params()) :: Changeset.t()
  def changeset(clinical, attrs) do
    clinical
    |> cast(attrs, [
      :reasons_for_test,
      :has_symptoms,
      :symptoms,
      :test,
      :laboratory_report,
      :test_kind,
      :result,
      :symptom_start
    ])
    |> cast_embed(:sponsor)
    |> cast_embed(:reporting_unit)
    |> validate_required([])
    |> clear_symptoms()
  end

  defp clear_symptoms(changeset) do
    current_symptoms = Ecto.Changeset.get_field(changeset, :symptoms)

    changeset
    |> Ecto.Changeset.fetch_change(:has_symptoms)
    |> case do
      :error ->
        changeset

      {:ok, nil} when is_nil(current_symptoms) ->
        changeset

      {:ok, nil} ->
        Ecto.Changeset.put_change(changeset, :symptoms, nil)

      {:ok, false} when is_nil(current_symptoms) ->
        changeset

      {:ok, false} ->
        Ecto.Changeset.put_change(changeset, :symptoms, nil)

      {:ok, true} when is_nil(current_symptoms) ->
        Ecto.Changeset.put_change(changeset, :symptoms, [])

      {:ok, true} ->
        changeset
    end
  end

  @spec merge(old :: t() | Changeset.t(t()), new :: t() | Changeset.t(t())) :: Changeset.t(t())
  def merge(old, new) do
    merge(old, new, __MODULE__, fn embed, old_embed, new_embed
                                   when embed in [:sponsor, :reporting_unit] ->
      Entity.merge(old_embed, new_embed)
    end)
  end
end
