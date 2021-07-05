defmodule HygeiaWeb.CaseLive.Index do
  @moduledoc false

  use HygeiaWeb, :surface_view

  import Ecto.Query

  alias Hygeia.CaseContext
  alias Hygeia.CaseContext.Case
  alias Hygeia.CaseContext.Case.Status
  alias Hygeia.Repo
  alias Hygeia.TenantContext
  alias Hygeia.UserContext
  alias Surface.Components.Form
  alias Surface.Components.Form.Checkbox
  alias Surface.Components.Form.Field
  alias Surface.Components.Form.FieldContext
  alias Surface.Components.Form.Input.InputContext
  alias Surface.Components.Form.Label
  alias Surface.Components.Form.MultipleSelect
  alias Surface.Components.Form.RadioButton
  alias Surface.Components.Link
  alias Surface.Components.LivePatch
  alias Surface.Components.LiveRedirect

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    socket =
      if authorized?(Case, :list, get_auth(socket), tenant: :any) do
        Phoenix.PubSub.subscribe(Hygeia.PubSub, "cases")

        supervisor_users = [
          %{display_name: gettext("Case Administration"), uuid: :user_not_assigned}
          | UserContext.list_users_with_role(:supervisor, :any)
        ]

        tracer_users = [
          %{display_name: gettext("Case Administration"), uuid: :user_not_assigned}
          | UserContext.list_users_with_role(:tracer, :any)
        ]

        assign(socket,
          page_title: gettext("Cases"),
          supervisor_users: supervisor_users,
          tracer_users: tracer_users,
          authorized_tenants:
            Enum.filter(
              TenantContext.list_tenants(),
              &authorized?(Case, :list, get_auth(socket), tenant: &1)
            )
        )
      else
        socket
        |> push_redirect(to: Routes.home_index_path(socket, :index))
        |> put_flash(:error, gettext("You are not authorized to do this action."))
      end

    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def handle_params(params, _uri, socket) do
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
                  "status" =>
                    Enum.map(
                      Case.Status.__enum_map__() --
                        [:done, :hospitalization, :home_resident, :canceled],
                      &Atom.to_string/1
                    ),
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

    {:noreply, socket}
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
    "phase_type" => :phase_type,
    "fully_vaccinated" => :fully_vaccinated,
    "vaccination_failures" => :vaccination_failures
  }

  defp list_cases(socket) do
    {cursor_fields, query} = sort_params(socket)
    user_not_assigned = Atom.to_string(:user_not_assigned)

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
        {:fully_vaccinated, "true"}, query ->
          where(
            query,
            [case, person: person],
            fragment("(?->>'done')::boolean", person.vaccination) and
              fragment("JSONB_ARRAY_LENGTH(?)", fragment("?->'jab_dates'", person.vaccination)) >=
                2 and
              fragment("(?->'jab_dates'->>-1)::date", person.vaccination) >= ago(6, "month")
          )

        {:vaccination_failures, "false"}, query ->
          query

        {:vaccination_failures, "true"}, query ->
          where(
            query,
            [case, person: person],
            fragment("(?->>'done')::boolean", person.vaccination) and
              fragment("JSONB_ARRAY_LENGTH(?)", fragment("?->'jab_dates'", person.vaccination)) >=
                2 and
              fragment("(?->'jab_dates'->>-1)::date", person.vaccination) >= ago(6, "month") and
              case.inserted_at >= fragment("(?->'jab_dates'->>-1)::date", person.vaccination)
          )

        {:fully_vaccinated, "false"}, query ->
          query

        {_key, value}, query when value in ["", nil] ->
          query

        {:tracer_uuid, [^user_not_assigned]}, query ->
          where(query, [case], is_nil(field(case, :tracer_uuid)))

        {:tracer_uuid, [^user_not_assigned | value]}, query ->
          where(
            query,
            [case],
            is_nil(field(case, :tracer_uuid)) or field(case, :tracer_uuid) in ^value
          )

        {:supervisor_uuid, [^user_not_assigned]}, query ->
          where(query, [case], is_nil(field(case, :supervisor_uuid)))

        {:supervisor_uuid, [^user_not_assigned | value]}, query ->
          where(
            query,
            [case],
            is_nil(field(case, :supervisor_uuid)) or field(case, :supervisor_uuid) in ^value
          )

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

    assign(socket, pagination: metadata, cases: Repo.preload(entries, person: [tenant: []]))
  rescue
    ArgumentError -> reraise HygeiaWeb.InvalidPaginationParamsError, __STACKTRACE__
  end

  defp base_query(socket),
    do:
      from(case in CaseContext.list_cases_query(),
        where: case.tenant_uuid in ^Enum.map(socket.assigns.authorized_tenants, & &1.uuid),
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
        as: :phase,
        preload: [:tenant]
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
        {[], base_query(socket)},
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
