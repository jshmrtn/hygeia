defmodule HygeiaWeb.CaseLive.Index do
  @moduledoc false

  use HygeiaWeb, :surface_view

  import Ecto.Query

  alias Hygeia.CaseContext
  alias Hygeia.CaseContext.Case
  alias Hygeia.Repo
  alias Hygeia.UserContext
  alias Surface.Components.Form
  alias Surface.Components.Form.FieldContext
  alias Surface.Components.Form.Input.InputContext
  alias Surface.Components.Form.MultipleSelect
  alias Surface.Components.Link
  alias Surface.Components.LivePatch
  alias Surface.Components.LiveRedirect

  @impl Phoenix.LiveView
  def mount(params, session, socket) do
    socket =
      if authorized?(Case, :list, get_auth(socket)) do
        Phoenix.PubSub.subscribe(Hygeia.PubSub, "cases")

        pagination_params =
          case params do
            %{"cursor" => cursor, "cursor_direction" => "after"} -> [after: cursor]
            %{"cursor" => cursor, "cursor_direction" => "before"} -> [before: cursor]
            _other -> []
          end

        supervisor_users = UserContext.list_users_with_role(:supervisor)
        tracer_users = UserContext.list_users_with_role(:tracer)

        socket
        |> assign(
          pagination_params: pagination_params,
          filters: %{},
          supervisor_users: supervisor_users,
          tracer_users: tracer_users
        )
        |> list_cases()
      else
        socket
        |> push_redirect(to: Routes.page_path(socket, :index))
        |> put_flash(:error, gettext("You are not authorized to do this action."))
      end

    super(params, session, socket)
  end

  @impl Phoenix.LiveView
  def handle_event("filter", params, socket) do
    {:noreply, socket |> assign(filters: params["filter"] || %{}) |> list_cases()}
  end

  @impl Phoenix.LiveView
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
    "supervisor_uuid" => :supervisor_uuid
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
        {key, value}, query when is_list(value) ->
          where(query, [case], field(case, ^key) in ^value)
      end)
      |> Repo.paginate(
        Keyword.merge(socket.assigns.pagination_params, cursor_fields: [inserted_at: :asc])
      )

    assign(socket,
      pagination: metadata,
      cases: Repo.preload(entries, person: [], tracer: [], supervisor: [])
    )
  end
end
