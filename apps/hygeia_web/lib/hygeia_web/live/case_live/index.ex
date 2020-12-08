defmodule HygeiaWeb.CaseLive.Index do
  @moduledoc false

  use HygeiaWeb, :surface_view

  import Ecto.Query

  alias Hygeia.CaseContext
  alias Hygeia.CaseContext.Case
  alias Hygeia.Repo
  alias Hygeia.UserContext
  alias Surface.Components.Form
  alias Surface.Components.Form.Field
  alias Surface.Components.Form.FieldContext
  alias Surface.Components.Form.Input.InputContext
  alias Surface.Components.Form.MultipleSelect
  alias Surface.Components.Form.RadioButton
  alias Surface.Components.Link
  alias Surface.Components.LivePatch
  alias Surface.Components.LiveRedirect

  @impl Phoenix.LiveView
  def mount(params, session, socket) do
    socket =
      if authorized?(Case, :list, get_auth(socket)) do
        Phoenix.PubSub.subscribe(Hygeia.PubSub, "cases")

        supervisor_users = UserContext.list_users_with_role(:supervisor)
        tracer_users = UserContext.list_users_with_role(:tracer)

        assign(socket, supervisor_users: supervisor_users, tracer_users: tracer_users)
      else
        socket
        |> push_redirect(to: Routes.home_path(socket, :index))
        |> put_flash(:error, gettext("You are not authorized to do this action."))
      end

    super(params, session, socket)
  end

  @impl Phoenix.LiveView
  def handle_params(params, uri, socket) do
    pagination_params =
      case params do
        %{"cursor" => cursor, "cursor_direction" => "after"} -> [after: cursor]
        %{"cursor" => cursor, "cursor_direction" => "before"} -> [before: cursor]
        _other -> []
      end

    socket =
      case {params["filter"], params["sort"]} do
        {nil, sort} ->
          push_patch(socket,
            to:
              page_url(
                socket,
                pagination_params,
                %{
                  "status" => Enum.map(Case.Status.__enum_map__() -- [:done], &Atom.to_string/1),
                  "tracer_uuid" => [get_auth(socket).uuid]
                },
                sort
              )
          )

        {filter, nil} ->
          push_patch(socket,
            to:
              page_url(socket, pagination_params, filter, [
                "asc_person_last_name",
                "asc_person_first_name"
              ])
          )

        {filter, sort} ->
          socket
          |> assign(pagination_params: pagination_params, filters: filter, sort: sort)
          |> list_cases()
      end

    super(params, uri, socket)
  end

  @impl Phoenix.LiveView
  def handle_event("filter", params, socket) do
    {:noreply,
     push_patch(socket,
       to: page_url(socket, [], params["filter"], socket.assigns.sort)
     )}
  end

  def handle_event("delete", %{"id" => id}, socket) do
    case = CaseContext.get_case!(id)

    true = authorized?(case, :delete, get_auth(socket))

    {:ok, _} = CaseContext.delete_case(case)

    {:noreply, list_cases(socket)}
  end

  @impl Phoenix.LiveView
  def handle_info({_type, %Case{}, _version}, socket) do
    {:noreply, list_cases(socket)}
  end

  def handle_info(_other, socket), do: {:noreply, socket}

  @allowed_filter_fields %{
    "status" => :status,
    "complexity" => :complexity,
    "tracer_uuid" => :tracer_uuid,
    "supervisor_uuid" => :supervisor_uuid,
    "phase_type" => :phase_type
  }

  defp list_cases(socket) do
    {cursor_fields, query} = sort_params(socket)

    %Paginator.Page{entries: entries, metadata: metadata} =
      socket.assigns.filters
      |> Enum.map(fn {key, value} ->
        {@allowed_filter_fields[key], value}
      end)
      |> Enum.reject(&match?({nil, _value}, &1))
      |> Enum.reject(&match?({_key, nil}, &1))
      # credo:disable-for-next-line Credo.Check.Design.DuplicatedCode
      |> Enum.reject(&match?({_key, []}, &1))
      |> Enum.reduce(query, fn
        {_key, value}, query when value in ["", nil] ->
          query

        {key, value}, query when is_list(value) ->
          where(query, [case], field(case, ^key) in ^value)

        {:phase_type, phase_type}, query ->
          phase_match = %{details: %{__type__: phase_type}}
          where(query, [case], fragment("? <@ ANY (?)", ^phase_match, case.phases))
      end)
      |> Repo.paginate(
        Keyword.merge(socket.assigns.pagination_params, cursor_fields: cursor_fields)
      )

    entries =
      if Keyword.has_key?(socket.assigns.pagination_params, :before) do
        Enum.reverse(entries)
      else
        entries
      end

    assign(socket, pagination: metadata, cases: entries)
  end

  defp base_query,
    do:
      from(case in CaseContext.list_cases_query(),
        join: person in assoc(case, :person),
        as: :person,
        preload: [person: person],
        left_join: tracer in assoc(case, :tracer),
        as: :tracer,
        preload: [tracer: tracer],
        left_join: supervisor in assoc(case, :supervisor),
        as: :supervisor,
        preload: [supervisor: supervisor],
        left_join:
          phase in fragment("UNNEST(ARRAY[?[ARRAY_UPPER(?, 1)]])", case.phases, case.phases),
        as: :phase
      )

  @sort_mapping %{
    "person_last_name" => {:person, :last_name},
    "person_first_name" => {:person, :first_name},
    "inserted_at" => :inserted_at,
    "complexity" => :complexity,
    "status" => :status,
    "tracer" => {:tracer, :display_name},
    "supervisor" => {:supervisor, :display_name},
    "phases" => {:phase, :type}
  }
  @sort_allowed_fields Map.keys(@sort_mapping)

  defp sort_params(socket) do
    {cursor_fields, query} =
      socket.assigns.sort
      |> Enum.map(fn
        "asc_" <> field when field in @sort_allowed_fields ->
          {@sort_mapping[field], :asc}

        "desc_" <> field when field in @sort_allowed_fields ->
          {@sort_mapping[field], :desc}
      end)
      |> Enum.reduce(
        {[], base_query()},
        fn
          {{:phase, :type}, direction} = cursor, {cursor_params, query} ->
            {[cursor | cursor_params],
             from([case, phase: phase] in query,
               order_by: [{^direction, fragment("?->'details'->>'type'", phase)}]
             )}

          {{relation_name, field}, direction} = cursor, {cursor_params, query} ->
            {[cursor | cursor_params],
             from([case, {^relation_name, relation}] in query,
               order_by: [{^direction, field(relation, ^field)}]
             )}

          {field, direction} = cursor, {cursor_params, query} ->
            {[cursor | cursor_params],
             from(case in query, order_by: [{^direction, field(case, ^field)}])}
        end
      )

    cursor_fields = Enum.reverse(cursor_fields)

    {cursor_fields, query}
  end

  defp page_url(socket, pagination_params, filters, sort)

  defp page_url(socket, [], filters, sort),
    do: Routes.case_index_path(socket, :index, filter: filters || %{}, sort: sort || %{})

  defp page_url(socket, [{cursor_direction, cursor}], filters, sort),
    do:
      Routes.case_index_path(socket, :index, cursor_direction, cursor,
        filter: filters || %{},
        sort: sort || %{}
      )
end
