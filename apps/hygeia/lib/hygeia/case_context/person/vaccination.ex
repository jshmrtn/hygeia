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

  embedded_schema do
    field :done, :boolean
    field :name, :string
    field :jab_dates, {:array, :date}
  end

  @doc false
  @spec changeset(vaccination :: t | empty, attrs :: Hygeia.ecto_changeset_params()) ::
          Changeset.t()
  def changeset(vaccination, attrs) do
    vaccination
    |> cast(attrs, [:uuid, :done, :name, :jab_dates])
    |> fill_uuid
    |> validate_change(:jab_dates, fn :jab_dates, jab_dates ->
      if Enum.member?(jab_dates, nil) do
        [jab_dates: dgettext("errors", "can't be blank")]
      else
        []
      end
    end)
  end
end
