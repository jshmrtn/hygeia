defmodule HygeiaWeb.PersonOverviewLive.Index do
  @moduledoc false

  use HygeiaWeb, :surface_view

  alias Hygeia.CaseContext
  alias Hygeia.CaseContext.Case
  alias Hygeia.CaseContext.Case.Phase
  alias Hygeia.CaseContext.Person
  alias Hygeia.Repo
  alias Surface.Components.Link
  alias Surface.Components.LiveRedirect

  @impl Phoenix.LiveView
  def handle_params(%{"person_uuid" => person_uuid}, _uri, socket) do
    person = CaseContext.get_person!(person_uuid)

    socket =
      if authorized?(person, :partial_details, get_auth(socket)) do
        socket
        |> assign(page_title: "#{person.first_name} #{person.last_name} - #{gettext("Person")}")
        |> load_data(person)
      else
        push_redirect(socket,
          to:
            Routes.auth_login_path(socket, :login,
              person_uuid: person.uuid,
              return_url: Routes.person_overview_index_path(socket, :index, person)
            )
        )
      end

    {:noreply, socket}
  end

  @impl Phoenix.LiveView
  def handle_info({:updated, %Person{} = person, _version}, socket) do
    {:noreply, load_data(socket, person)}
  end

  def handle_info({:deleted, %Person{}, _version}, socket) do
    {:noreply, redirect(socket, to: Routes.home_index_path(socket, :index))}
  end

  def handle_info({:updated, %Case{} = case, _version}, socket) do
    case = Repo.preload(case, person: [cases: [:tracer]])
    {:noreply, load_data(socket, case.person)}
  end

  def handle_info({:deleted, %Case{}, _version}, socket) do
    {:noreply, load_data(socket, CaseContext.get_person!(socket.assigns.person.uuid))}
  end

  defp load_data(socket, person) do
    person = Repo.preload(person, cases: [:tracer, :tenant])

    Phoenix.PubSub.subscribe(Hygeia.PubSub, "people:#{person.uuid}")

    for %Case{uuid: uuid} <- person.cases do
      Phoenix.PubSub.subscribe(Hygeia.PubSub, "cases:#{uuid}")
    end

    {active_phase, active_case} =
      person.cases
      |> Enum.flat_map(fn %Case{phases: phases} = case ->
        Enum.map(phases, &{&1, case})
      end)
      |> Enum.filter(&match?({%Phase{quarantine_order: true}, _case}, &1))
      |> Enum.find(
        {nil, nil},
        fn {%Phase{start: start_date, end: end_date}, _case} ->
          Enum.member?(Date.range(start_date, end_date), Date.utc_today())
        end
      )

    assign(socket, person: person, active_phase: active_phase, active_case: active_case)
  end
end
