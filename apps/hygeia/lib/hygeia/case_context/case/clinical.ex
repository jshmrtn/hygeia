defmodule Hygeia.CaseContext.Case.Clinical do
  @moduledoc """
  Model for Clinical Schema
  """

  use Hygeia, :model

  import EctoEnum

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

  @type empty :: %__MODULE__{
          reasons_for_test: [TestReason.t()] | nil,
          has_symptoms: boolean() | nil,
          symptoms: [Symptom.t()] | nil,
          symptom_start: Date.t() | nil
        }

  @type t :: %__MODULE__{
          reasons_for_test: [TestReason.t()],
          has_symptoms: boolean() | nil,
          symptoms: [Symptom.t()],
          symptom_start: Date.t() | nil
        }

  embedded_schema do
    field :reasons_for_test, {:array, TestReason}
    field :has_symptoms, :boolean
    field :symptoms, {:array, Symptom}
    field :symptom_start, :date
  end

  @doc false
  @spec changeset(clinical :: t | empty, attrs :: Hygeia.ecto_changeset_params()) :: Changeset.t()
  def changeset(clinical, attrs) do
    clinical
    |> cast(attrs, [
      :reasons_for_test,
      :has_symptoms,
      :symptoms,
      :symptom_start
    ])
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
  def merge(old, new), do: merge(old, new, __MODULE__)
end
