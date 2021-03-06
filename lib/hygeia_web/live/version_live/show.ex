defmodule HygeiaWeb.VersionLive.Show do
  @moduledoc false

  use HygeiaWeb, :surface_view

  import HygeiaWeb.Helpers.Versioning

  alias Hygeia.Repo
  alias Hygeia.VersionContext

  data versions, :list, default: []
  data now, :map
  data resource, :map
  data schema, :map

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    socket = assign(socket, now: DateTime.utc_now())

    :timer.send_interval(:timer.seconds(1), :tick)

    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def handle_params(%{"id" => id, "resource" => resource}, _uri, socket) do
    schema = item_table_to_module(resource)

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
      |> VersionContext.get_versions(id)
      |> Enum.reverse()

    socket =
      assign(socket,
        page_title: gettext("History"),
        schema: schema,
        resource: preload(resource),
        versions: versions,
        id: id,
        now: DateTime.utc_now()
      )

    {:noreply, socket}
  catch
    :unauthorized ->
      socket =
        socket
        |> push_redirect(to: Routes.home_index_path(socket, :index))
        |> put_flash(:error, gettext("You are not authorized to do this action."))

      {:noreply, socket}
  end

  @impl Phoenix.LiveView
  def handle_info(:tick, socket) do
    {:noreply, assign(socket, now: DateTime.utc_now())}
  end

  def handle_info(_other, socket), do: {:noreply, socket}

  @impl Phoenix.LiveView
  def render(%{resource: %Hygeia.CaseContext.Case{} = case} = assigns) do
    ~F"""
    <div class="component-versioning case container">
      <HygeiaWeb.PersonLive.Header person={case.person} id="header" />

      <div class="card">
        <div class="card-header">
          <HygeiaWeb.CaseLive.Navigation case={case} id="navigation" />
        </div>
        <div class="card-body">
          <HygeiaWeb.VersionLive.Table
            versions={@versions}
            now={@now}
            id={"resource_#{@id}_version_table"}
          />
        </div>
      </div>
    </div>
    """
  end

  def render(%{resource: %Hygeia.CaseContext.Person{} = person} = assigns) do
    ~F"""
    <div class="component-versioning person container">
      <HygeiaWeb.PersonLive.Header person={person} id="header" />

      <HygeiaWeb.VersionLive.Table
        versions={@versions}
        now={@now}
        id={"resource_#{@id}_version_table"}
      />
    </div>
    """
  end

  def render(%{resource: %Hygeia.CaseContext.Transmission{} = transmission} = assigns) do
    ~F"""
    <div class="component-versioning transmission container">
      <HygeiaWeb.TransmissionLive.Header transmission={transmission} id="header" />

      <HygeiaWeb.VersionLive.Table
        versions={@versions}
        now={@now}
        id={"resource_#{@id}_version_table"}
      />
    </div>
    """
  end

  def render(%{resource: %Hygeia.UserContext.User{} = user} = assigns) do
    ~F"""
    <div class="component-versioning user container">
      <HygeiaWeb.UserLive.Header user={user} id="header" />

      <HygeiaWeb.VersionLive.Table
        versions={@versions}
        now={@now}
        id={"resource_#{@id}_version_table"}
      />
    </div>
    """
  end

  def render(%{resource: %Hygeia.TenantContext.Tenant{} = tenant} = assigns) do
    ~F"""
    <div class="component-versioning tenant container">
      <HygeiaWeb.TenantLive.Header tenant={tenant} id="header" />

      <HygeiaWeb.VersionLive.Table
        versions={@versions}
        now={@now}
        id={"resource_#{@id}_version_table"}
      />
    </div>
    """
  end

  def render(%{resource: %Hygeia.OrganisationContext.Division{} = division} = assigns) do
    ~F"""
    <div class="component-versioning division container">
      <HygeiaWeb.DivisionLive.Header division={division} id="header" />

      <HygeiaWeb.VersionLive.Table
        versions={@versions}
        now={@now}
        id={"resource_#{@id}_version_table"}
      />
    </div>
    """
  end

  def render(%{resource: %Hygeia.OrganisationContext.Organisation{} = organisation} = assigns) do
    ~F"""
    <div class="component-versioning organisation container">
      <HygeiaWeb.OrganisationLive.Header organisation={organisation} id="header" />

      <HygeiaWeb.VersionLive.Table
        versions={@versions}
        now={@now}
        id={"resource_#{@id}_version_table"}
      />
    </div>
    """
  end

  def render(%{resource: %Hygeia.ImportContext.Import{} = import} = assigns) do
    ~F"""
    <div class="component-versioning import container">
      <HygeiaWeb.ImportLive.Header import={import} id="header" />

      <HygeiaWeb.VersionLive.Table
        versions={@versions}
        now={@now}
        id={"resource_#{@id}_version_table"}
      />
    </div>
    """
  end

  def render(assigns) do
    ~F"""
    <div class="component-versioning container">
      <h1>
        {module_translation(@schema)}
        /
        {@id}
      </h1>

      <HygeiaWeb.VersionLive.Table
        versions={@versions}
        now={@now}
        id={"resource_#{@id}_version_table"}
      />
    </div>
    """
  end

  defp preload(%Hygeia.CaseContext.Case{} = case),
    do: Repo.preload(case, person: [tenant: []], tenant: [])

  defp preload(other), do: other
end
