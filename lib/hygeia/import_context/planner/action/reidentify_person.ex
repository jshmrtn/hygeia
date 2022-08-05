defmodule Hygeia.ImportContext.Planner.Action.ReidentifyPerson do
  @moduledoc """
  Reidentify Person
  """

  @type action :: :reidentify | :skip | :stop
  @type t :: %__MODULE__{action: action()}

  defstruct [:action]

  defimpl Hygeia.ImportContext.Planner.Action do
    alias Ecto.Changeset
    alias Hygeia.ImportContext.Planner.Action.ReidentifyPerson

    @impl Hygeia.ImportContext.Planner.Action
    def execute(%ReidentifyPerson{action: :skip}, _preceding_results, _row), do: {:ok, %{}}

    def execute(
          %ReidentifyPerson{action: :reidentify},
          %{person_changeset: person_changeset},
          _row
        ),
        do:
          {:ok,
           %{
             person_changeset:
               Changeset.change(person_changeset, %{
                 redacted: false,
                 reidentification_date: Date.utc_today()
               })
           }}
  end
end
