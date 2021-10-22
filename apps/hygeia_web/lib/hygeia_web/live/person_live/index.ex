defmodule HygeiaWeb.PersonLive.Index do
  @moduledoc false

  use HygeiaWeb, :surface_view

  import Ecto.Query

  alias Hygeia.CaseContext
  alias Hygeia.CaseContext.Person
  alias Hygeia.EctoType.NOGA
  alias Hygeia.Repo
  alias Hygeia.TenantContext
  alias Surface.Components.Form
  alias Surface.Components.Form.Checkbox
  alias Surface.Components.Form.Field
  alias Surface.Components.Form.Input.InputContext
  alias Surface.Components.Form.Label
  alias Surface.Components.Form.MultipleSelect
  alias Surface.Components.Form.RadioButton
  alias Surface.Components.Form.Select
  alias Surface.Components.Link
  alias Surface.Components.LivePatch
  alias Surface.Components.LiveRedirect

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    socket =
      if authorized?(Person, :list, get_auth(socket), tenant: :any) do
        Phoenix.PubSub.subscribe(Hygeia.PubSub, "people")

        assign(socket,
          page_title: gettext("People"),
          tenants: TenantContext.list_tenants(),
          authorized_tenants:
            Enum.filter(
              TenantContext.list_tenants(),
              &authorized?(Person, :list, get_auth(socket), tenant: &1)
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

    filter = Map.put_new(params["filter"] || %{}, "tenant_persons", Enum.map(socket.assigns.authorized_tenants, & &1.uuid))

    socket =
      case params["sort"] do
        nil ->
          push_patch(socket,
            to:
              page_url(socket, pagination_params, filter, [
                "asc_last_name",
                "asc_first_name"
              ])
          )

        sort ->
          socket
          |> assign(pagination_params: pagination_params, filters: filter, sort: sort)
          |> list_people()
      end

    {:noreply, socket}
  end

  @impl Phoenix.LiveView
  def handle_event("filter", params, socket) do
    {:noreply,
     push_patch(socket, to: page_url(socket, [], params["filter"] || %{}, socket.assigns.sort))}
  end

  def handle_event("delete", %{"id" => id}, socket) do
    person = CaseContext.get_person!(id)

    true = authorized?(person, :delete, get_auth(socket))

    {:ok, _} = CaseContext.delete_person(person)

    {:noreply, list_people(socket)}
  end

  @impl Phoenix.LiveView
  def handle_info({_type, %Person{}, _version}, socket) do
    {:noreply, list_people(socket)}
  end

  def handle_info(_other, socket), do: {:noreply, socket}

  @allowed_filter_fields %{
    "tenant_persons" => :tenant_persons,
    "profession_category_main" => :profession_category_main,
    "sex" => :sex,
    "country" => :country,
    "subdivision" => :subdivision,
    "fully_vaccinated" => :fully_vaccinated
  }

  defp list_people(socket) do
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
        {:tenant_persons, selected_tenant_uuids}, query ->
          where(
            query,
            [person],
            person.tenant_uuid in ^selected_tenant_uuids
          )

        {:fully_vaccinated, "true"}, query ->
          where(
            query,
            [person],
            fragment("(?->>'done')::boolean", person.vaccination) and
              fragment("JSONB_ARRAY_LENGTH(?)", fragment("?->'jab_dates'", person.vaccination)) >=
                2 and
              fragment("(?->'jab_dates'->>-1)::date", person.vaccination) >= ago(6, "month")
          )

        {:fully_vaccinated, "false"}, query ->
          query

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
        Keyword.merge(socket.assigns.pagination_params, cursor_fields: cursor_fields)
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
  rescue
    ArgumentError -> reraise HygeiaWeb.InvalidPaginationParamsError, __STACKTRACE__
  end

  @sort_mapping %{
    "last_name" => :last_name,
    "first_name" => :first_name,
    "inserted_at" => :inserted_at,
    "birth_date" => :birth_date
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
        fn {field, direction} = cursor, {cursor_params, query} ->
          {[cursor | cursor_params],
           from(person in query, order_by: [{^direction, field(person, ^field)}])}
        end
      )

    cursor_fields = Enum.reverse(cursor_fields)

    {cursor_fields, query}
  end

  defp base_query(_socket) do
    from(person in CaseContext.list_people_query(), preload: [:tenant])
  end

  defp page_url(socket, pagination_params, filters, sort)

  defp page_url(socket, [], filters, sort),
    do: Routes.person_index_path(socket, :index, filter: filters || %{}, sort: sort || %{})

  defp page_url(socket, [{cursor_direction, cursor}], filters, sort),
    do:
      Routes.person_index_path(socket, :index, cursor_direction, cursor,
        filter: filters || %{},
        sort: sort || %{}
      )
end
