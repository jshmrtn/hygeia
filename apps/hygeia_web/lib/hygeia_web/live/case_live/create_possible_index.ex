defmodule HygeiaWeb.CaseLive.CreatePossibleIndex do
  @moduledoc false

  use HygeiaWeb, :surface_view

  import HygeiaWeb.CaseLive.Create

  alias Hygeia.CaseContext
  alias Hygeia.CaseContext.Case
  alias Hygeia.CaseContext.Case.Phase
  alias Hygeia.CaseContext.PossibleIndexSubmission
  alias Hygeia.CommunicationContext
  alias Hygeia.Repo
  alias Hygeia.TenantContext
  alias Hygeia.UserContext
  alias HygeiaWeb.CaseLive.Create.CreatePersonSchema
  alias HygeiaWeb.CaseLive.CreatePossibleIndex.CreateSchema
  alias HygeiaWeb.DateInput
  alias Surface.Components.Form
  alias Surface.Components.Form.Checkbox
  alias Surface.Components.Form.ErrorTag
  alias Surface.Components.Form.Field
  alias Surface.Components.Form.HiddenInput
  alias Surface.Components.Form.Input.InputContext
  alias Surface.Components.Form.Inputs

  alias Surface.Components.Form.RadioButton
  alias Surface.Components.Form.Select
  alias Surface.Components.Form.TextInput

  @impl Phoenix.LiveView
  # credo:disable-for-next-line Credo.Check.Design.DuplicatedCode
  def mount(params, _session, socket) do
    socket =
      if authorized?(Case, :create, get_auth(socket), tenant: :any) do
        tenants =
          Enum.filter(
            TenantContext.list_tenants(),
            &authorized?(Case, :create, get_auth(socket), tenant: &1)
          )

        supervisor_users = UserContext.list_users_with_role(:supervisor, tenants)
        tracer_users = UserContext.list_users_with_role(:tracer, tenants)

        auth_user = get_auth(socket)

        changeset_attrs =
          params
          |> Map.put_new("default_tracer_uuid", auth_user.uuid)
          |> Map.put_new("default_supervisor_uuid", auth_user.uuid)

        changeset_attrs =
          case params["possible_index_submission_uuid"] do
            nil -> changeset_attrs
            uuid -> Map.merge(changeset_attrs, possible_index_submission_attrs(uuid))
          end

        assign(socket,
          changeset: CreateSchema.changeset(%CreateSchema{people: []}, changeset_attrs),
          tenants: tenants,
          supervisor_users: supervisor_users,
          tracer_users: tracer_users,
          suspected_duplicate_changeset_uuid: nil,
          file: nil,
          return_to: params["return_to"],
          loading: false,
          page_title: "#{gettext("Create Possible Index Cases")} - #{gettext("Cases")}"
        )
      else
        socket
        |> push_redirect(to: Routes.home_index_path(socket, :index))
        |> put_flash(:error, gettext("You are not authorized to do this action."))
      end

    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def handle_params(_params, _uri, socket) do
    {:noreply, assign(socket, suspected_duplicate_changeset_uuid: nil)}
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
        %CreateSchema{
          propagator_case_uuid: propagator_case_uuid,
          possible_index_submission_uuid: possible_index_submission_uuid
        } = global = Ecto.Changeset.apply_changes(changeset)

        propagator_case =
          case propagator_case_uuid do
            nil -> nil
            id -> id |> CaseContext.get_case!() |> Repo.preload(person: [])
          end

        {:ok, {cases, transmissions}} =
          Repo.transaction(fn ->
            cases =
              changeset
              |> CreateSchema.drop_empty_rows()
              |> Ecto.Changeset.fetch_field!(:people)
              |> Enum.map(&{&1, CreatePersonSchema.upsert(&1, socket, global, propagator_case)})
              |> Enum.map(&CreateSchema.upsert_case(&1, global))

            transmissions = Enum.map(cases, &CreateSchema.create_transmission(&1, global))

            :ok = close_submission(possible_index_submission_uuid)

            {cases, transmissions}
          end)

        :ok = send_confirmation_sms(socket, global, cases)

        :ok = send_confirmation_emails(socket, global, cases)

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
         update_changeset_param(
           socket.assigns.changeset,
           :propagator_case_uuid,
           fn _value_before -> params["uuid"] end
         )
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
     |> assign(
       changeset: import_into_changeset(socket.assigns.changeset, data, CreateSchema),
       loading: false
     )
     |> maybe_block_navigation()}
  end

  def handle_info({:csv_import, {:error, _reason}}, socket) do
    {:noreply,
     socket
     |> put_flash(:error, gettext("Could not parse CSV"))
     |> assign(loading: false)}
  end

  def handle_info({:accept_duplicate, uuid, case_or_person}, socket) do
    {:noreply,
     socket
     |> assign(
       changeset: accept_duplicate(socket.assigns.changeset, uuid, case_or_person, CreateSchema)
     )
     |> maybe_block_navigation()}
  end

  def handle_info({:declined_duplicate, uuid}, socket) do
    {:noreply,
     socket
     |> assign(changeset: decline_duplicate(socket.assigns.changeset, uuid, CreateSchema))
     |> maybe_block_navigation()}
  end

  def handle_info({:remove_person, uuid}, socket) do
    {:noreply,
     socket
     |> assign(changeset: remove_person(socket.assigns.changeset, uuid, CreateSchema))
     |> maybe_block_navigation()}
  end

  def handle_info(_other, socket), do: {:noreply, socket}

  defp possible_index_submission_attrs(uuid) do
    %PossibleIndexSubmission{
      case_uuid: case_uuid,
      transmission_date: transmission_date,
      infection_place: infection_place,
      first_name: first_name,
      last_name: last_name,
      sex: sex,
      birth_date: birth_date,
      mobile: mobile,
      landline: landline,
      email: email,
      address: address,
      employer: employer
    } = CaseContext.get_possible_index_submission!(uuid)

    %{
      "propagator_internal" => true,
      "propagator_case_uuid" => case_uuid,
      "type" => :contact_person,
      "date" => Date.to_iso8601(transmission_date),
      "infection_place" =>
        infection_place
        |> Map.from_struct()
        |> Map.put(:address, Map.from_struct(infection_place.address))
        |> Map.drop([:type]),
      "people" => [
        %{
          first_name: first_name,
          last_name: last_name,
          sex: sex,
          birth_date: birth_date,
          mobile: mobile,
          landline: landline,
          email: email,
          address: Map.from_struct(address),
          employer: employer
        }
      ]
    }
  end

  defp close_submission(uuid)
  defp close_submission(nil), do: :ok

  defp close_submission(uuid) do
    {:ok, _possible_index_submission} =
      uuid
      |> CaseContext.get_possible_index_submission!()
      |> CaseContext.delete_possible_index_submission()

    :ok
  end

  defp send_confirmation_emails(socket, global, cases)

  defp send_confirmation_emails(_socket, %CreateSchema{send_confirmation_email: false}, _cases),
    do: :ok

  defp send_confirmation_emails(
         socket,
         %CreateSchema{send_confirmation_email: true, type: type},
         cases
       ) do
    locale = Gettext.get_locale(HygeiaGettext)

    [] =
      cases
      |> Enum.map(
        &Task.async(fn ->
          case List.last(&1.phases) do
            %Phase{details: %Phase.PossibleIndex{type: ^type}} = phase ->
              Gettext.put_locale(HygeiaGettext, locale)

              CommunicationContext.create_outgoing_email(
                &1,
                quarantine_email_subject(),
                quarantine_email_body(socket, &1, phase, :email)
              )

            %Phase{} ->
              {:error, :not_latest_phase}
          end
        end)
      )
      |> Enum.map(&Task.await/1)
      # credo:disable-for-next-line Credo.Check.Design.DuplicatedCode
      |> Enum.reject(&match?({:ok, _}, &1))
      |> Enum.reject(&match?({:error, :no_email}, &1))
      |> Enum.reject(&match?({:error, :no_outgoing_mail_configuration}, &1))
      |> Enum.reject(&match?({:error, :not_latest_phase}, &1))

    :ok
  end

  defp send_confirmation_sms(socket, global, cases)

  defp send_confirmation_sms(_socket, %CreateSchema{send_confirmation_sms: false}, _cases),
    do: :ok

  defp send_confirmation_sms(
         socket,
         %CreateSchema{send_confirmation_sms: true, type: type},
         cases
       ) do
    locale = Gettext.get_locale(HygeiaGettext)

    [] =
      cases
      |> Enum.map(
        &Task.async(fn ->
          case List.last(&1.phases) do
            %Phase{details: %Phase.PossibleIndex{type: ^type}} = phase ->
              Gettext.put_locale(HygeiaGettext, locale)

              CommunicationContext.create_outgoing_sms(&1, quarantine_sms(socket, &1, phase))

            %Phase{} ->
              {:error, :not_latest_phase}
          end
        end)
      )
      |> Enum.map(&Task.await/1)
      |> Enum.reject(&match?({:ok, _}, &1))
      |> Enum.reject(&match?({:error, :no_mobile_number}, &1))
      |> Enum.reject(&match?({:error, :sms_config_missing}, &1))
      |> Enum.reject(&match?({:error, :not_latest_phase}, &1))

    :ok
  end

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
