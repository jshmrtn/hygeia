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
      case params["filter"] do
        nil ->
          push_patch(socket,
            to:
              page_url(socket, pagination_params, %{
                "status" => Enum.map(Case.Status.__enum_map__() -- [:done], &Atom.to_string/1),
                "tracer_uuid" => [get_auth(socket).uuid]
              })
          )

        %{} ->
          socket
      end

    filter = params["filter"] || %{}

    socket =
      socket
      |> assign(pagination_params: pagination_params, filters: filter)
      |> list_cases()

    super(params, uri, socket)
  end

  @impl Phoenix.LiveView
  def handle_event("filter", params, socket) do
    {:noreply,
     push_patch(socket,
       to: page_url(socket, socket.assigns.pagination_params, params["filter"] || %{})
     )}
  end

  def handle_event("delete", %{"id" => id}, socket) do
    case = CaseContext.get_case!(id)

    true = authorized?(case, :delete, get_auth(socket))

    {:ok, _} = CaseContext.delete_case(case)

    {:noreply, socket |> assign(pagination_params: []) |> list_cases()}
  end

  @impl Phoenix.LiveView
  def handle_info({_type, %Case{}, _version}, socket) do
    {:noreply, socket |> assign(pagination_params: []) |> list_cases()}
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
    %Paginator.Page{entries: entries, metadata: metadata} =
      socket.assigns.filters
      |> Enum.map(fn {key, value} ->
        {@allowed_filter_fields[key], value}
      end)
      |> Enum.reject(&match?({nil, _value}, &1))
      |> Enum.reject(&match?({_key, nil}, &1))
      # credo:disable-for-next-line Credo.Check.Design.DuplicatedCode
      |> Enum.reject(&match?({_key, []}, &1))
      |> Enum.reduce(CaseContext.list_cases_query(), fn
        {_key, value}, query when value in ["", nil] ->
          query

        {key, value}, query when is_list(value) ->
          where(query, [case], field(case, ^key) in ^value)

        {:phase_type, phase_type}, query ->
          phase_match = %{details: %{__type__: phase_type}}
          where(query, [case], fragment("? <@ ANY (?)", ^phase_match, case.phases))
      end)
      |> Repo.paginate(
        Keyword.merge(socket.assigns.pagination_params, cursor_fields: [inserted_at: :asc])
      )

    entries =
      if Keyword.has_key?(socket.assigns.pagination_params, :before) do
        Enum.reverse(entries)
      else
        entries
      end

    assign(socket,
      pagination: metadata,
      cases: Repo.preload(entries, person: [], tracer: [], supervisor: [])
    )
  end

  defp page_url(socket, pagination_params, filters)

  defp page_url(socket, [], filters),
    do: Routes.case_index_path(socket, :index, filter: filters || %{})

  defp page_url(socket, [{cursor_direction, cursor}], filters),
    do: Routes.case_index_path(socket, :index, cursor_direction, cursor, filter: filters || %{})
end
