defmodule Hygeia.ImportContext.Planner.Action.AddNote do
  @moduledoc """
  Add Note
  """

  @type t :: %__MODULE__{
          action: :append | :skip,
          note: String.t() | nil,
          pinned: boolean | nil
        }

  defstruct [:action, :note, :pinned]

  defimpl Hygeia.ImportContext.Planner.Action do
    alias Ecto.Changeset
    alias Hygeia.CaseContext.Note
    alias Hygeia.ImportContext.Planner.Action.AddNote

    @impl Hygeia.ImportContext.Planner.Action
    def execute(%AddNote{action: :skip}, _preceding_results, _row),
      do: {:ok, %{note_changeset: nil}}

    def execute(
          %AddNote{action: :append, note: note, pinned: pinned},
          _preceding_results,
          _row
        ),
        do:
          {:ok,
           %{
             note_changeset:
               Changeset.change(%Note{}, %{
                 note: note,
                 pinned: pinned
               })
           }}
  end
end
