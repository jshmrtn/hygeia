defmodule HygeiaWeb.PersonOverviewLive.Index do
  @moduledoc false

  use HygeiaWeb, :surface_view

  alias Hygeia.AutoTracingContext.AutoTracing
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
        {socket, redirect_to_auto_tracing} =
          socket
          |> assign(page_title: "#{person.first_name} #{person.last_name} - #{gettext("Person")}")
          |> load_data(person)

        case redirect_to_auto_tracing do
          %Case{} = case ->
            push_redirect(socket,
              to: Routes.auto_tracing_auto_tracing_path(socket, :auto_tracing, case)
            )

          false ->
            socket
        end
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
    {socket, redirect_to_auto_tracing} =
      load_data(socket, CaseContext.get_person!(socket.assigns.person.uuid))

    {:noreply,
     case redirect_to_auto_tracing do
       %Case{} = case ->
         push_redirect(socket,
           to: Routes.auto_tracing_auto_tracing_path(socket, :auto_tracing, case)
         )

       false ->
         socket
     end}
  end

  defp load_data(socket, person) do
    person = Repo.preload(person, cases: [:tracer, :tenant, :auto_tracing])

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

    untraced_index_cases =
      for case <- person.cases,
          match?(%Case{auto_tracing: %AutoTracing{}}, case),
          phase <- case.phases,
          match?(%Phase{details: %Phase.Index{}, quarantine_order: nil}, phase) do
        case
      end

    redirect_to_auto_tracing =
      case untraced_index_cases do
        [case | _others] -> case
        [] -> false
      end

    sorted_case_phases =
      Enum.sort_by(
        for case <- person.cases, phase <- case.phases do
          {phase, case}
        end,
        fn
          {%Phase{end: nil, inserted_at: nil}, %Case{inserted_at: inserted_at}} -> inserted_at
          {%Phase{end: nil, inserted_at: inserted_at}, _case} -> inserted_at
          {%Phase{end: end_date}, _case} -> end_date
        end,
        {:desc, Date}
      )

    {assign(socket,
       person: person,
       active_phase: active_phase,
       active_case: active_case,
       sorted_case_phases: sorted_case_phases
     ), redirect_to_auto_tracing}
  end
end
