defmodule HygeiaWeb.VersionLive.Show do
  @moduledoc false

  use HygeiaWeb, :surface_view

  alias Hygeia.Repo

  data versions, :list, default: []
  data now, :map
  data resource, :map
  data schema, :map

  @impl Phoenix.LiveView
  def mount(params, session, socket) do
    socket = assign(socket, now: DateTime.utc_now())

    :timer.send_interval(:timer.seconds(1), :tick)

    super(params, session, socket)
  end

  @impl Phoenix.LiveView
  def handle_params(%{"id" => id, "resource" => resource} = params, uri, socket) do
    schema = item_type_to_module(resource)

    resource = Repo.get(schema, id)

    case resource do
      nil ->
        unless authorized?(schema, :deleted_versioning, get_auth(socket)),
          do: throw(:unauthorized)

      %^schema{} ->
        unless authorized?(resource, :versioning, get_auth(socket)), do: throw(:unauthorized)
    end

    versions =
      schema
      |> PaperTrail.get_versions(id, [])
      |> Enum.sort_by(& &1.inserted_at, {:desc, DateTime})

    socket =
      assign(socket,
        schema: schema,
        resource: preload(resource),
        versions: versions,
        id: id,
        now: DateTime.utc_now()
      )

    super(params, uri, socket)
  catch
    :unauthorized ->
      socket =
        socket
        |> push_redirect(to: Routes.home_path(socket, :index))
        |> put_flash(:error, gettext("You are not authorized to do this action."))

      super(params, uri, socket)
  end

  @impl Phoenix.LiveView
  def handle_info(:tick, socket) do
    {:noreply, assign(socket, now: DateTime.utc_now())}
  end

  def handle_info({:put_flash, type, msg}, socket), do: {:noreply, put_flash(socket, type, msg)}

  def handle_info(_other, socket), do: {:noreply, socket}

  @impl Phoenix.LiveView
  def render(%{resource: %Hygeia.CaseContext.Case{} = case} = assigns) do
    ~H"""
    <div class="component-versioning case container">
      <HygeiaWeb.PersonLive.Header person={{ case.person }} id="header" />

      <div class="card">
        <div class="card-header">
          <HygeiaWeb.CaseLive.Navigation case={{ case }} id="navigation" />
        </div>
        <div class="card-body">
          {{ render_table(assigns) }}
        </div>
      </div>
    </div>
    """
  end

  def render(%{resource: %Hygeia.CaseContext.Person{} = person} = assigns) do
    ~H"""
    <div class="component-versioning person container">
      <HygeiaWeb.PersonLive.Header person={{ person }} id="header" />

      {{ render_table(assigns) }}
    </div>
    """
  end

  def render(%{resource: %Hygeia.CaseContext.Transmission{} = transmission} = assigns) do
    ~H"""
    <div class="component-versioning transmission container">
      <HygeiaWeb.TransmissionLive.Header transmission={{ transmission }} id="header" />

      {{ render_table(assigns) }}
    </div>
    """
  end

  def render(%{resource: %Hygeia.UserContext.User{} = user} = assigns) do
    ~H"""
    <div class="component-versioning user container">
      <HygeiaWeb.UserLive.Header user={{ user }} id="header" />

      {{ render_table(assigns) }}
    </div>
    """
  end

  def render(%{resource: %Hygeia.TenantContext.Tenant{} = tenant} = assigns) do
    ~H"""
    <div class="component-versioning tenant container">
      <HygeiaWeb.TenantLive.Header tenant={{ tenant }} id="header" />

      {{ render_table(assigns) }}
    </div>
    """
  end

  def render(%{resource: %Hygeia.OrganisationContext.Organisation{} = organisation} = assigns) do
    ~H"""
    <div class="component-versioning organisation container">
      <HygeiaWeb.OrganisationLive.Header organisation={{ organisation }} id="header" />

      {{ render_table(assigns) }}
    </div>
    """
  end

  def render(assigns) do
    ~H"""
    <div class="component-versioning container">
      <h1>
        {{ module_translation(@schema) }} / {{ @id }}
      </h1>
      {{ render_table(assigns) }}
    </div>
    """
  end

  defp render_table(assigns) do
    ~H"""
    <HygeiaWeb.VersionLive.Table
      versions={{ @versions }}
      now={{ @now }}
      id={{ "resource_#{@id}_version_table" }}
    />
    """
  end

  defp preload(%Hygeia.CaseContext.Case{} = case),
    do: Repo.preload(case, person: [tenant: []], tenant: [])

  defp preload(other), do: other
end
