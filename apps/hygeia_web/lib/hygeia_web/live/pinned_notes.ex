defmodule HygeiaWeb.PinnedNotes do
  @moduledoc false

  use HygeiaWeb, :surface_live_component

  alias Hygeia.CaseContext
  alias Hygeia.Repo

  prop person, :map, required: true

  @impl Phoenix.LiveComponent
  def preload(assign_list) do
    preload_assigns_one(assign_list, :person, &Repo.preload(&1, :pinned_notes))
  end

  @impl Phoenix.LiveComponent
  def handle_event("unpinn_note", %{"note-id" => note_id}, socket) do
    note = CaseContext.get_note!(note_id)
    {:ok, _note} = CaseContext.update_note(note, %{pinned: false})

    {:noreply,
     assign(socket, person: Repo.preload(socket.assigns.person, :pinned_notes, force: true))}
  end
end
