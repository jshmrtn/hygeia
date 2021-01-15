defmodule HygeiaWeb.NoteLive.CreateModal do
  @moduledoc false

  use HygeiaWeb, :surface_live_component

  alias Hygeia.CaseContext
  alias Hygeia.CaseContext.Note
  alias Surface.Components.Form
  alias Surface.Components.Form.ErrorTag
  alias Surface.Components.Form.Field
  alias Surface.Components.Form.TextArea

  prop case, :map, required: true
  prop close, :event, required: true
  prop params, :map, default: %{}
  prop caller_id, :any, required: true
  prop caller_module, :atom, required: true

  @impl Phoenix.LiveComponent
  def update(assigns, socket) do
    case = assigns.case || socket.assigns.case
    params = assigns.params || socket.assigns.params

    changeset = case |> Ecto.build_assoc(:notes) |> CaseContext.change_note(params)

    {:ok, socket |> assign(assigns) |> assign(changeset: changeset)}
  end

  @impl Phoenix.LiveComponent
  def handle_event("validate", %{"note" => note_params}, socket) do
    {:noreply,
     socket
     |> assign(
       changeset: %{
         (socket.assigns.case
          |> Ecto.build_assoc(:notes)
          |> CaseContext.change_note(note_params))
         | action: :validate
       }
     )
     |> maybe_block_navigation()}
  end

  def handle_event(
        "save",
        %{"note" => note_params},
        socket
      ) do
    true = authorized?(Note, :create, get_auth(socket), %{case: socket.assigns.case})

    socket.assigns.case
    |> CaseContext.create_note(note_params)
    |> handle_save_response(socket)
  end

  defp handle_save_response({:ok, _note}, socket) do
    send_update(socket.assigns.caller_module,
      id: socket.assigns.caller_id,
      __close_note_modal__: true
    )

    send(self(), {:put_flash, :info, gettext("Note created successfully")})

    {
      :noreply,
      socket
    }
  end

  defp handle_save_response({:error, %Ecto.Changeset{} = changeset}, socket),
    do:
      {:noreply,
       socket
       |> assign(changeset: changeset)
       |> maybe_block_navigation()}

  defp maybe_block_navigation(%{assigns: %{changeset: %{changes: changes}}} = socket) do
    if changes == %{} do
      push_event(socket, "unblock_navigation", %{})
    else
      push_event(socket, "block_navigation", %{})
    end
  end
end
