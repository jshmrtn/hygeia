defmodule Hygeia.CaseContext.Case.Clinical do
  @moduledoc """
  Model for Clinical Schema
  """

  use Hygeia, :model

  alias Hygeia.CaseContext.Case.Clinical.Symptom
  alias Hygeia.CaseContext.Case.Clinical.TestReason

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

  @type changeset_params :: %{optional(:symptoms_required) => boolean()}

  embedded_schema do
    field :reasons_for_test, {:array, TestReason}
    field :has_symptoms, :boolean
    field :symptoms, {:array, Symptom}
    field :symptom_start, :date
  end

  @doc false
  @spec changeset(
          clinical :: t | empty,
          attrs :: Hygeia.ecto_changeset_params(),
          changeset_params :: changeset_params
        ) :: Changeset.t()
  def changeset(clinical, attrs, changeset_params \\ %{})

  def changeset(clinical, attrs, %{symptoms_required: true} = changeset_params) do
    clinical
    |> changeset(attrs, %{changeset_params | symptoms_required: false})
    |> validate_required([:has_symptoms])
    |> validate_required_when_has_symptoms()
  end

  def changeset(clinical, attrs, _changeset_params) do
    clinical
    |> cast(attrs, [
      :reasons_for_test,
      :has_symptoms,
      :symptoms,
      :symptom_start
    ])
    |> validate_required([])
    |> validate_past_date(:symptom_start)
    |> clear_symptoms()
  end

  defp validate_required_when_has_symptoms(changeset) do
    changeset
    |> fetch_field!(:has_symptoms)
    |> case do
      nil ->
        changeset

      true ->
        changeset
        |> validate_required([:symptoms, :symptom_start])
        |> validate_length(:symptoms, min: 1)

      false ->
        changeset
        |> put_change(:symptom_start, nil)
        |> put_change(:symptoms, [])
    end
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
