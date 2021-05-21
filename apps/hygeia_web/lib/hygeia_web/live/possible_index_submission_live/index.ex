defmodule HygeiaWeb.PossibleIndexSubmissionLive.Index do
  @moduledoc false

  use HygeiaWeb, :surface_view

  alias Hygeia.CaseContext
  alias Hygeia.CaseContext.Case
  alias Hygeia.CaseContext.Case.Phase
  alias Hygeia.CaseContext.Person
  alias Hygeia.CaseContext.PossibleIndexSubmission
  alias Hygeia.Repo
  alias Surface.Components.Context
  alias Surface.Components.Link
  alias Surface.Components.LiveRedirect

  @impl Phoenix.LiveView
  def mount(%{"case_uuid" => case_uuid} = _params, _session, socket) do
    case = CaseContext.get_case!(case_uuid)

    socket =
      if authorized?(PossibleIndexSubmission, :list, get_auth(socket), %{case: case}) do
        Phoenix.PubSub.subscribe(Hygeia.PubSub, "cases:#{case_uuid}")
        Phoenix.PubSub.subscribe(Hygeia.PubSub, "possible_index_submissions")

        load_data(socket, case_uuid)
      else
        push_redirect(socket,
          to:
            Routes.auth_login_path(socket, :login,
              person_uuid: case.person_uuid,
              return_url: Routes.possible_index_submission_index_path(socket, :index, case)
            )
        )
      end

    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def handle_event("delete", %{"id" => id}, socket) do
    possible_index_submission = CaseContext.get_possible_index_submission!(id)

    true = authorized?(possible_index_submission, :delete, get_auth(socket))

    {:ok, _} = CaseContext.delete_possible_index_submission(possible_index_submission)

    {:noreply, socket}
  end

  @impl Phoenix.LiveView
  def handle_info({_type, %PossibleIndexSubmission{}, _version}, socket),
    do: {:noreply, load_data(socket, socket.assigns.case.uuid)}

  def handle_info(_other, socket), do: {:noreply, socket}

  defp load_data(socket, case_uuid) do
    case =
      case_uuid
      |> CaseContext.get_case!()
      |> Repo.preload(person: [tenant: []], possible_index_submissions: [], tenant: [])

    has_index_phase? = Enum.any?(case.phases, &match?(%Phase{details: %Phase.Index{}}, &1))

    assign(socket,
      case: case,
      has_index_phase?: has_index_phase?,
      page_title:
        "#{case.person.first_name} #{case.person.last_name} - #{gettext("Possible Index Submissions")} - #{gettext("Case")}"
    )
  end
end
