defmodule HygeiaWeb.PossibleIndexSubmissionLive.Show do
  @moduledoc false

  use HygeiaWeb, :surface_view

  alias Hygeia.CaseContext
  alias Hygeia.CaseContext.Case
  alias Hygeia.CaseContext.PossibleIndexSubmission
  alias Hygeia.Repo
  alias HygeiaWeb.DateInput
  alias Surface.Components.Form
  alias Surface.Components.Form.ErrorTag
  alias Surface.Components.Form.Field
  alias Surface.Components.Form.Inputs

  alias Surface.Components.Form.TextInput
  alias Surface.Components.Link
  alias Surface.Components.LivePatch
  alias Surface.Components.LiveRedirect

  @impl Phoenix.LiveView
  def handle_params(%{"id" => id}, _uri, socket) do
    possible_index_submission = CaseContext.get_possible_index_submission!(id)

    socket =
      if authorized?(
           possible_index_submission,
           case socket.assigns.live_action do
             :edit -> :update
             :show -> :details
           end,
           get_auth(socket)
         ) do
        Phoenix.PubSub.subscribe(Hygeia.PubSub, "possible_index_submissions:#{id}")

        load_data(socket, possible_index_submission)
      else
        socket
        |> push_redirect(to: Routes.home_index_path(socket, :index))
        |> put_flash(:error, gettext("You are not authorized to do this action."))
      end

    {:noreply, socket}
  end

  @impl Phoenix.LiveView
  def handle_info({:updated, %PossibleIndexSubmission{} = possible_index_submission}, socket) do
    {:noreply, assign(socket, :possible_index_submission, possible_index_submission)}
  end

  def handle_info({:deleted, %PossibleIndexSubmission{}, _version}, socket) do
    {:noreply,
     redirect(socket,
       to:
         Routes.possible_index_submission_index_path(
           socket,
           :index,
           socket.assigns.possible_index_submission.case
         )
     )}
  end

  def handle_info(_other, socket), do: {:noreply, socket}

  @impl Phoenix.LiveView
  def handle_event("reset", _params, socket) do
    possible_index_submission =
      CaseContext.get_possible_index_submission!(socket.assigns.possible_index_submission.uuid)

    {:noreply,
     socket
     |> load_data(possible_index_submission)
     |> push_patch(
       to: Routes.possible_index_submission_show_path(socket, :show, possible_index_submission)
     )
     |> maybe_block_navigation()}
  end

  def handle_event(
        "validate",
        %{"possible_index_submission" => possible_index_submission_params},
        socket
      ) do
    {:noreply,
     socket
     |> assign(:changeset, %{
       CaseContext.change_possible_index_submission(
         socket.assigns.possible_index_submission,
         possible_index_submission_params
       )
       | action: :validate
     })
     |> maybe_block_navigation()}
  end

  def handle_event("delete", _params, socket) do
    true = authorized?(socket.assigns.possible_index_submission, :delete, get_auth(socket))

    {:ok, _} =
      CaseContext.delete_possible_index_submission(socket.assigns.possible_index_submission)

    {:noreply,
     socket
     |> put_flash(:info, gettext("PossibleIndexSubmission deleted successfully"))
     |> redirect(
       to:
         Routes.possible_index_submission_index_path(
           socket,
           :index,
           socket.assigns.possible_index_submission.case
         )
     )}
  end

  def handle_event(
        "save",
        %{"possible_index_submission" => possible_index_submission_params},
        socket
      ) do
    true = authorized?(socket.assigns.possible_index_submission, :update, get_auth(socket))

    socket.assigns.possible_index_submission
    |> CaseContext.update_possible_index_submission(possible_index_submission_params)
    |> case do
      {:ok, possible_index_submission} ->
        {:noreply,
         socket
         |> load_data(possible_index_submission)
         |> put_flash(:info, gettext("PossibleIndexSubmission updated successfully"))
         |> push_patch(
           to:
             Routes.possible_index_submission_show_path(socket, :show, possible_index_submission)
         )}

      {:error, changeset} ->
        {:noreply,
         socket
         |> assign(changeset: changeset)
         |> maybe_block_navigation()}
    end
  end

  defp load_data(socket, possible_index_submission) do
    possible_index_submission =
      Repo.preload(possible_index_submission, case: [person: [tenant: []], tenant: []])

    changeset = CaseContext.change_possible_index_submission(possible_index_submission)

    socket
    |> assign(possible_index_submission: possible_index_submission, changeset: changeset)
    |> maybe_block_navigation()
  end

  defp maybe_block_navigation(%{assigns: %{changeset: %{changes: changes}}} = socket) do
    if changes == %{} do
      push_event(socket, "unblock_navigation", %{})
    else
      push_event(socket, "block_navigation", %{})
    end
  end
end
