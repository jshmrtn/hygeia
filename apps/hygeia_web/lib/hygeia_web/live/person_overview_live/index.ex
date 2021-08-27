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
  def handle_info({:deleted, %Person{}, _version}, socket) do
    {:noreply, redirect(socket, to: Routes.home_index_path(socket, :index))}
  end

  def handle_info({action, _entity, _version}, socket)
      when action in [:created, :updated, :deleted] do
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
      |> Enum.filter(&match?({%Phase{quarantine_order: true, end: %Date{}}, _case}, &1))
      |> Enum.sort_by(fn {%Phase{end: end_date}, _case} -> end_date end, {:desc, Date})
      |> Enum.find(
        {nil, nil},
        fn {%Phase{start: start_date, end: end_date}, _case} ->
          Enum.member?(Date.range(start_date, end_date), Date.utc_today())
        end
      )

    sorted_case_phases =
      Enum.sort_by(
        for case <- person.cases, phase <- case.phases do
          {phase, case}
        end,
        fn {%Phase{end: end_date}, _case} -> end_date end,
        {:desc, Date}
      )

    assign(socket,
      person: person,
      active_phase: active_phase,
      active_case: active_case,
      sorted_case_phases: sorted_case_phases
    )
  end
end
