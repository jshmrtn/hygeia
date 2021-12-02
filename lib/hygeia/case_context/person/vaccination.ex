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

  @type changeset_options :: %{
          optional(:required) => boolean,
          optional(:initial_nil_jab_date_count) => integer
        }

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

  def changeset(
        vaccination,
        attrs,
        %{required: true, initial_nil_jab_date_count: 0}
      ) do
    vaccination
    |> do_changeset(attrs)
    |> remove_nil_jab_dates()
    |> validate_details_required()
  end

  def changeset(
        vaccination,
        attrs,
        %{required: true, initial_nil_jab_date_count: nil_count}
      ) do
    vaccination
    |> do_changeset(attrs)
    |> validate_details_required()
    |> validate_initial_jab_dates(nil_count)
  end

  def changeset(vaccination, attrs, %{required: true} = changeset_options) do
    vaccination
    |> changeset(attrs, %{changeset_options | required: false})
    |> validate_required([:done])
    |> validate_details_required()
  end

  def changeset(vaccination, attrs, _changeset_options) do
    vaccination
    |> do_changeset(attrs)
    |> validate_details_required()
    |> validate_change(:jab_dates, fn :jab_dates, jab_dates ->
      if Enum.member?(jab_dates, nil) do
        [jab_dates: dgettext("errors", "can't be blank")]
      else
        []
      end
    end)
  end

  defp do_changeset(vaccination, attrs) do
    vaccination
    |> cast(attrs, [:uuid, :done, :name, :jab_dates])
    |> fill_uuid
    |> validate_dates()
  end

  defp validate_dates(changeset) do
    validate_change(changeset, :jab_dates, fn :jab_dates, jab_dates ->
      if Enum.all?(jab_dates, &(is_nil(&1) or Date.compare(&1, Date.utc_today()) in [:lt, :eq])) do
        []
      else
        [jab_dates: dgettext("errors", "jab dates must be in the past")]
      end
    end)
  end

  defp validate_details_required(changeset) do
    case fetch_field!(changeset, :done) do
      true ->
        changeset
        |> validate_required([:name, :jab_dates])
        |> validate_change(:jab_dates, fn
          :jab_dates, dates ->
            if Enum.reject(dates, &is_nil/1) == [] do
              [jab_dates: dgettext("errors", "at least one date must be provided")]
            else
              []
            end
        end)

      _other ->
        changeset
        |> put_change(:name, nil)
        |> put_change(:jab_dates, nil)
    end
  end

  defp validate_initial_jab_dates(changeset, nil_count) do
    case fetch_field!(changeset, :done) do
      true ->
        changeset
        |> add_nil_jab_dates(nil_count)
        |> validate_change(:jab_dates, fn
          :jab_dates, dates ->
            {_initial, rest} = Enum.split(dates, nil_count)

            if Enum.member?(rest, nil) do
              [jab_dates: dgettext("errors", "can't be blank")]
            else
              []
            end
        end)

      _other ->
        changeset
    end
  end

  defp add_nil_jab_dates(changeset, count) do
    changeset
    |> fetch_field!(:jab_dates)
    |> case do
      nil ->
        changeset

      list ->
        list
        |> Kernel.length()
        |> case do
          length when length < count ->
            put_change(
              changeset,
              :jab_dates,
              changeset
              |> fetch_field!(:jab_dates)
              |> Enum.concat(List.duplicate(nil, count - length))
            )

          _else ->
            changeset
        end
    end
  end

  defp remove_nil_jab_dates(changeset) do
    put_change(
      changeset,
      :jab_dates,
      changeset
      |> fetch_field!(:jab_dates)
      |> Enum.reject(&is_nil/1)
    )
  end
end
