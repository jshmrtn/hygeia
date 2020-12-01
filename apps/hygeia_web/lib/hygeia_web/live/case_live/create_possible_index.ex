defmodule HygeiaWeb.CaseLive.CreatePossibleIndex do
  @moduledoc false

  use HygeiaWeb, :surface_view

  import HygeiaWeb.CaseLive.Create

  alias Hygeia.CaseContext
  alias Hygeia.CaseContext.Case
  alias Hygeia.Repo
  alias Hygeia.TenantContext
  alias Hygeia.UserContext
  alias HygeiaWeb.CaseLive.Create.CreatePersonSchema
  alias HygeiaWeb.CaseLive.CreatePossibleIndex.CreateSchema
  alias Surface.Components.Form
  alias Surface.Components.Form.DateInput
  alias Surface.Components.Form.ErrorTag
  alias Surface.Components.Form.Field
  alias Surface.Components.Form.HiddenInput
  alias Surface.Components.Form.Input.InputContext
  alias Surface.Components.Form.Inputs
  alias Surface.Components.Form.Label
  alias Surface.Components.Form.RadioButton
  alias Surface.Components.Form.Select
  alias Surface.Components.Form.TextInput

  @impl Phoenix.LiveView
  # credo:disable-for-next-line Credo.Check.Design.DuplicatedCode
  def mount(params, session, socket) do
    socket =
      if authorized?(Case, :create, get_auth(socket)) do
        tenants = TenantContext.list_tenants()
        supervisor_users = UserContext.list_users_with_role(:supervisor)
        tracer_users = UserContext.list_users_with_role(:tracer)
        infection_place_types = CaseContext.list_infection_place_types()
        auth_user = get_auth(socket)

        assign(socket,
          changeset:
            CreateSchema.changeset(
              %CreateSchema{people: []},
              params
              |> Map.put_new("default_tracer_uuid", auth_user.uuid)
              |> Map.put_new("default_supervisor_uuid", auth_user.uuid)
              |> Map.put_new("default_country", "CH")
            ),
          tenants: tenants,
          supervisor_users: supervisor_users,
          tracer_users: tracer_users,
          infection_place_types: infection_place_types,
          suspected_duplicate_changeset_uuid: nil,
          file: nil,
          return_to: params["return_to"],
          loading: false
        )
      else
        socket
        |> push_redirect(to: Routes.home_path(socket, :index))
        |> put_flash(:error, gettext("You are not authorized to do this action."))
      end

    super(params, session, socket)
  end

  @impl Phoenix.LiveView
  def handle_params(params, uri, socket) do
    super(params, uri, assign(socket, suspected_duplicate_changeset_uuid: nil))
  end

  @impl Phoenix.LiveView
  def handle_event("validate", %{"create_schema" => create_params}, socket) do
    {:noreply,
     socket
     |> assign(:changeset, %{
       CreateSchema.changeset(%CreateSchema{people: []}, create_params)
       | action: :validate
     })
     |> maybe_block_navigation()}
  end

  def handle_event("save", %{"create_schema" => create_params}, socket) do
    %CreateSchema{people: []}
    |> CreateSchema.changeset(create_params)
    |> case do
      %Ecto.Changeset{valid?: false} = changeset ->
        {:noreply,
         socket
         |> assign(changeset: changeset)
         |> maybe_block_navigation()}

      %Ecto.Changeset{valid?: true} = changeset ->
        {:ok, transmissions} =
          Repo.transaction(fn ->
            changeset
            |> Ecto.Changeset.fetch_field!(:people)
            |> Enum.reject(&match?(%CreatePersonSchema{uuid: nil}, &1))
            |> Enum.map(&{&1, save_or_load_person_schema(&1, socket, changeset)})
            |> Enum.map(&create_case(&1, changeset))
            |> Enum.map(&create_transmission(&1, changeset))
          end)

        socket =
          put_flash(
            socket,
            :info,
            ngettext("Created Case", "Created %{n} Cases", length(transmissions),
              n: length(transmissions)
            )
          )

        {:noreply, socket |> handle_save_success(CreateSchema) |> maybe_block_navigation()}
    end
  end

  def handle_event("change_propagator_case", params, socket) do
    {:noreply,
     socket
     |> assign(:changeset, %{
       CreateSchema.changeset(
         %CreateSchema{people: []},
         Map.put(socket.assigns.changeset.params, "propagator_case_uuid", params["uuid"])
       )
       | action: :validate
     })
     |> maybe_block_navigation()}
  end

  @impl Phoenix.LiveView
  def handle_info({:csv_import, :start}, socket) do
    {:noreply, assign(socket, loading: true)}
  end

  def handle_info({:csv_import, {:ok, data}}, socket) do
    {:noreply,
     socket
     |> assign(changeset: import_into_changeset(socket.assigns.changeset, data), loading: false)
     |> maybe_block_navigation()}
  end

  def handle_info({:csv_import, {:error, _reason}}, socket) do
    {:noreply,
     socket
     |> put_flash(:error, gettext("Could not parse CSV"))
     |> assign(loading: false)}
  end

  def handle_info({:accept_duplicate, uuid, person}, socket) do
    {:noreply,
     assign(socket,
       changeset: accept_duplicate(socket.assigns.changeset, uuid, person)
     )}
  end

  def handle_info({:declined_duplicate, uuid}, socket) do
    {:noreply, assign(socket, changeset: decline_duplicate(socket.assigns.changeset, uuid))}
  end

  def handle_info({:remove_person, uuid}, socket) do
    {:noreply,
     assign(socket,
       changeset: remove_person(socket.assigns.changeset, uuid)
     )}
  end

  def handle_info(_other, socket), do: {:noreply, socket}

  defp create_case({_person_schema, {person, supervisor, tracer}}, changeset) do
    {start_date, end_date} =
      changeset
      |> Ecto.Changeset.get_field(:date, nil)
      |> case do
        nil ->
          {nil, nil}

        %Date{} = contact_date ->
          start_date = Date.add(contact_date, 1)
          end_date = Date.add(start_date, 9)

          start_date =
            if Date.compare(start_date, Date.utc_today()) == :lt do
              Date.utc_today()
            else
              start_date
            end

          end_date =
            if Date.compare(end_date, Date.utc_today()) == :lt do
              Date.utc_today()
            else
              end_date
            end

          {start_date, end_date}
      end

    {:ok, case} =
      CaseContext.create_case(person, %{
        phases: [
          %{
            details: %{
              __type__: :possible_index,
              type: Ecto.Changeset.fetch_field!(changeset, :type)
            },
            start: start_date,
            end: end_date
          }
        ],
        supervisor_uuid: supervisor.uuid,
        tracer_uuid: tracer.uuid
      })

    case
  end

  defp create_transmission(case, changeset) do
    {:ok, transmission} =
      CaseContext.create_transmission(%{
        date: Ecto.Changeset.get_field(changeset, :date),
        recipient_internal: true,
        recipient_case_uuid: case.uuid,
        infection_place: changeset |> Ecto.Changeset.fetch_field!(:infection_place) |> unpack,
        propagator_internal: Ecto.Changeset.fetch_field!(changeset, :propagator_internal),
        propagator_ism_id: Ecto.Changeset.get_field(changeset, :propagator_ism_id),
        propagator_case_uuid: Ecto.Changeset.get_field(changeset, :propagator_case_uuid)
      })

    transmission
  end

  defp unpack(struct) when is_struct(struct) do
    struct
    |> Map.from_struct()
    |> Enum.map(fn {key, value} -> {key, unpack(value)} end)
    |> Map.new()
  end

  defp unpack(other), do: other

  defp maybe_block_navigation(%{assigns: %{changeset: changeset}} = socket) do
    changeset
    |> Ecto.Changeset.get_field(:people, [])
    |> case do
      [] -> push_event(socket, "unblock_navigation", %{})
      [_] -> push_event(socket, "unblock_navigation", %{})
      [_ | _] -> push_event(socket, "block_navigation", %{})
    end
  end
end
