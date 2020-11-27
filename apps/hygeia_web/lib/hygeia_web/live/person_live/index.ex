defmodule HygeiaWeb.PersonLive.Index do
  @moduledoc false

  use HygeiaWeb, :surface_view

  import Ecto.Query

  alias Hygeia.CaseContext
  alias Hygeia.CaseContext.Person
  alias Hygeia.Repo
  alias Surface.Components.Form
  alias Surface.Components.Form.Field
  alias Surface.Components.Form.Input.InputContext
  alias Surface.Components.Form.Label
  alias Surface.Components.Form.RadioButton
  alias Surface.Components.Form.Select
  alias Surface.Components.Link
  alias Surface.Components.LivePatch
  alias Surface.Components.LiveRedirect

  @impl Phoenix.LiveView
  def mount(params, session, socket) do
    socket =
      if authorized?(Person, :list, get_auth(socket)) do
        Phoenix.PubSub.subscribe(Hygeia.PubSub, "people")

        professions = CaseContext.list_professions()

        assign(socket, professions: professions)
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

    filter = params["filter"] || %{}

    socket =
      socket
      |> assign(pagination_params: pagination_params, filters: filter)
      |> list_people()

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
    person = CaseContext.get_person!(id)

    true = authorized?(person, :delete, get_auth(socket))

    {:ok, _} = CaseContext.delete_person(person)

    {:noreply, socket |> assign(pagination_params: []) |> list_people()}
  end

  @impl Phoenix.LiveView
  def handle_info({_type, %Person{}, _version}, socket) do
    {:noreply, socket |> assign(pagination_params: []) |> list_people()}
  end

  def handle_info(_other, socket), do: {:noreply, socket}

  @allowed_filter_fields %{
    "profession_uuid" => :profession_uuid,
    "sex" => :sex,
    "country" => :country,
    "subdivision" => :subdivision
  }

  defp list_people(socket) do
    %Paginator.Page{entries: entries, metadata: metadata} =
      socket.assigns.filters
      |> Enum.map(fn {key, value} ->
        {@allowed_filter_fields[key], value}
      end)
      |> Enum.reject(&match?({nil, _value}, &1))
      |> Enum.reject(&match?({_key, nil}, &1))
      # credo:disable-for-next-line Credo.Check.Design.DuplicatedCode
      |> Enum.reject(&match?({_key, []}, &1))
      |> Enum.reduce(CaseContext.list_people_query(), fn
        {_key, value}, query when value in ["", nil] ->
          query

        {:country, value}, query ->
          where(query, [person], fragment("?->'country'", person.address) == ^value)

        {:subdivision, value}, query ->
          where(query, [person], fragment("?->'subdivision'", person.address) == ^value)

        {key, [_ | _] = value}, query when is_list(value) ->
          where(query, [person], field(person, ^key) in ^value)

        {key, value}, query ->
          where(query, [person], field(person, ^key) == ^value)
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
      people: entries
    )
  end

  defp page_url(socket, pagination_params, filters)

  defp page_url(socket, [], filters),
    do: Routes.person_index_path(socket, :index, filter: filters || %{})

  defp page_url(socket, [{cursor_direction, cursor}], filters),
    do: Routes.person_index_path(socket, :index, cursor_direction, cursor, filter: filters || %{})
end
