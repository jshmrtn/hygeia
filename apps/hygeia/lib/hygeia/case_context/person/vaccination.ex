defmodule Hygeia.CaseContext.Person.Vaccination do
  @moduledoc """
  Model for Vaccination Schema
  """

  use Hygeia, :model

  import HygeiaGettext

  @type empty :: %__MODULE__{
          done: boolean() | nil,
          name: String.t() | nil,
          jab_dates: [Date.t()] | nil
        }

  @type t :: empty

  @type changeset_options :: %{optional(:required) => boolean}

  embedded_schema do
    field :done, :boolean
    field :name, :string
    field :jab_dates, {:array, :date}
  end

  @doc false
  @spec changeset(
          vaccination :: t | empty,
          attrs :: Hygeia.ecto_changeset_params(),
          changeset_options :: changeset_options
        ) ::
          Changeset.t()
  def changeset(vaccination, attrs \\ %{}, changeset_options \\ %{})

  def changeset(vaccination, attrs, %{required: true} = changeset_options) do
    vaccination
    |> changeset(attrs, %{changeset_options | required: false})
    |> validate_required([:done])
    |> validate_details_required()
  end

  def changeset(vaccination, attrs, _changeset_options) do
    vaccination
    |> cast(attrs, [:uuid, :done, :name, :jab_dates])
    |> fill_uuid
    |> validate_change(:jab_dates, fn
      :jab_dates, [_, _ | rest] = all ->
        cond do
          Enum.member?(rest, nil) ->
            [jab_dates: dgettext("errors", "can't be blank")]

          not Enum.any?(all) ->
            [jab_dates: dgettext("errors", "at least one date must be provided")]

          true ->
            []
        end

      :jab_dates, _else ->
        []
    end)
  end

  defp validate_details_required(changeset) do
    case fetch_field!(changeset, :done) do
      true ->
        changeset
        |> validate_required([:name, :jab_dates])
        |> validate_length(:jab_dates, min: 1)

      _other ->
        changeset
        |> put_change(:name, nil)
        |> put_change(:jab_dates, nil)
    end
  end
end
