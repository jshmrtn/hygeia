defmodule HygeiaWeb.CaseLive.BaseData do
  @moduledoc false

  use HygeiaWeb, :surface_view

  alias Hygeia.CaseContext
  alias Hygeia.CaseContext.Case
  alias Hygeia.CaseContext.Hospitalization
  alias Hygeia.CaseContext.Phase
  alias Hygeia.OrganisationContext
  alias Hygeia.OrganisationContext.Organisation
  alias Hygeia.Repo
  alias Hygeia.TenantContext
  alias Hygeia.UserContext
  alias HygeiaWeb.FormError
  alias HygeiaWeb.PolimorphicInputs
  alias Surface.Components.Form
  alias Surface.Components.Form.DateInput
  alias Surface.Components.Form.Field
  alias Surface.Components.Form.HiddenInput
  alias Surface.Components.Form.Input.InputContext
  alias Surface.Components.Form.Inputs
  alias Surface.Components.Form.Label
  alias Surface.Components.Form.Select
  alias Surface.Components.Link
  alias Surface.Components.LivePatch

  @impl Phoenix.LiveView
  def handle_params(%{"id" => id} = params, uri, socket) do
    case = CaseContext.get_case!(id)

    socket =
      if authorized?(
           case,
           case socket.assigns.live_action do
             :edit -> :update
             :show -> :details
           end,
           get_auth(socket)
         ) do
        Phoenix.PubSub.subscribe(Hygeia.PubSub, "cases:#{id}")

        tenants = TenantContext.list_tenants()
        supervisor_users = UserContext.list_users_with_role(:supervisor)
        tracer_users = UserContext.list_users_with_role(:tracer)
        organisations = OrganisationContext.list_organisations()

        socket
        |> load_data(case)
        |> assign(
          tenants: tenants,
          supervisor_users: supervisor_users,
          tracer_users: tracer_users,
          organisations: organisations
        )
      else
        socket
        |> push_redirect(to: Routes.home_path(socket, :index))
        |> put_flash(:error, gettext("You are not authorized to do this action."))
      end

    super(params, uri, socket)
  end

  @impl Phoenix.LiveView
  def handle_info({:updated, %Case{} = case, _version}, socket) do
    {:noreply, load_data(socket, case)}
  end

  def handle_info({:deleted, %Case{}, _version}, socket) do
    {:noreply, redirect(socket, to: Routes.case_index_path(socket, :index))}
  end

  def handle_info(_other, socket), do: {:noreply, socket}

  @impl Phoenix.LiveView
  def handle_event("reset", _params, socket) do
    case = CaseContext.get_case!(socket.assigns.case.uuid)

    {:noreply,
     socket
     |> load_data(socket.assigns.case)
     |> push_patch(to: Routes.case_base_data_path(socket, :show, case))
     |> maybe_block_navigation()}
  end

  def handle_event("validate", %{"case" => case_params}, socket) do
    case_params =
      case_params
      |> Map.put_new("hospitalizations", [])
      |> Map.put_new("external_references", [])
      |> Map.put_new("related_organisations", [])

    {:noreply,
     socket
     |> assign(:changeset, %{
       CaseContext.change_case(socket.assigns.case, case_params)
       | action: :validate
     })
     |> maybe_block_navigation()}
  end

  def handle_event("save", %{"case" => case_params}, socket) do
    case_params =
      case_params
      |> Map.put_new("hospitalizations", [])
      |> Map.put_new("external_references", [])
      |> Map.put_new("related_organisations", [])

    socket.assigns.case
    |> CaseContext.update_case(case_params)
    |> case do
      {:ok, case} ->
        {:noreply,
         socket
         |> load_data(case)
         |> put_flash(:info, gettext("Case updated successfully"))
         |> push_patch(to: Routes.case_base_data_path(socket, :show, case))}

      {:error, changeset} ->
        {:noreply,
         socket
         |> assign(changeset: changeset)
         |> maybe_block_navigation()}
    end
  end

  def handle_event("add_external_reference", _params, socket) do
    external_references =
      Ecto.Changeset.get_field(socket.assigns.changeset, :external_references, [])

    changeset =
      Ecto.Changeset.put_change(
        socket.assigns.changeset,
        :external_references,
        external_references ++ [%{}]
      )

    {:noreply,
     socket
     |> assign(:changeset, changeset)
     |> maybe_block_navigation()}
  end

  def handle_event("add_hospitalization", _params, socket) do
    hospitalizations = Ecto.Changeset.get_field(socket.assigns.changeset, :hospitalizations, [])

    changeset =
      Ecto.Changeset.put_change(
        socket.assigns.changeset,
        :hospitalizations,
        hospitalizations ++ [Hospitalization.changeset(%Hospitalization{}, %{})]
      )

    {:noreply,
     socket
     |> assign(:changeset, changeset)
     |> maybe_block_navigation()}
  end

  def handle_event("remove_hospitalization", %{"changeset-uuid" => uuid}, socket) do
    hospitalizations =
      socket.assigns.changeset
      |> Ecto.Changeset.get_field(:hospitalizations, [])
      |> Enum.map(&Hospitalization.changeset(&1, %{}))
      |> Enum.map(fn changeset ->
        if Ecto.Changeset.get_field(changeset, :uuid) == uuid,
          do: %{changeset | action: :delete},
          else: changeset
      end)

    changeset =
      Ecto.Changeset.put_embed(
        socket.assigns.changeset,
        :hospitalizations,
        hospitalizations
      )

    {:noreply,
     socket
     |> assign(:changeset, changeset)
     |> maybe_block_navigation()}
  end

  def handle_event("add_related_organisation", _params, socket) do
    organisations = Ecto.Changeset.get_field(socket.assigns.changeset, :related_organisations, [])

    changeset =
      Ecto.Changeset.put_change(
        socket.assigns.changeset,
        :related_organisations,
        organisations ++ [Organisation.changeset(%Organisation{}, %{})]
      )

    {:noreply,
     socket
     |> assign(:changeset, changeset)
     |> maybe_block_navigation()}
  end

  def handle_event("remove_related_organisation", params, socket) do
    related_organisations =
      socket.assigns.changeset
      |> Ecto.Changeset.get_change(
        :related_organisations,
        socket.assigns.changeset
        |> Ecto.Changeset.fetch_field!(:related_organisations)
        |> Enum.map(&Organisation.changeset(&1, %{}))
      )
      |> Enum.reject(&(Ecto.Changeset.get_field(&1, :uuid) == params["changeset-uuid"]))

    changeset =
      Ecto.Changeset.put_assoc(
        socket.assigns.changeset,
        :related_organisations,
        related_organisations
      )

    {:noreply,
     socket
     |> assign(:changeset, changeset)
     |> maybe_block_navigation()}
  end

  defp load_data(socket, case) do
    case = Repo.preload(case, person: [], related_organisations: [])

    changeset = CaseContext.change_case(case)

    socket
    |> assign(
      case: case,
      changeset: changeset,
      versions: PaperTrail.get_versions(case)
    )
    |> maybe_block_navigation()
  end

  defp maybe_block_navigation(%{assigns: %{changeset: %{changes: changes}}} = socket) do
    if changes == %{} do
      push_event(socket, "unblock_navigation", %{})
    else
      push_event(socket, "block_navigation", %{})
    end
  end
end
