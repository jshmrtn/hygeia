# credo:disable-for-this-file Credo.Check.Readability.StrictModuleLayout
defmodule HygeiaWeb.RowLive.Apply do
  @moduledoc false

  use HygeiaWeb, :surface_view

  alias Hygeia.CaseContext
  alias Hygeia.CaseContext.Case
  alias Hygeia.ImportContext
  alias Hygeia.ImportContext.Import.Type
  alias Hygeia.ImportContext.Planner
  alias Hygeia.ImportContext.Planner.Action
  alias Hygeia.ImportContext.Row
  alias Hygeia.Repo
  alias Hygeia.TenantContext
  alias Hygeia.UserContext
  alias Surface.Components.Form
  alias Surface.Components.Form.Field
  alias Surface.Components.Form.HiddenInput
  alias Surface.Components.Form.Label
  alias Surface.Components.Form.Select
  alias Surface.Components.Form.TextInput
  alias Surface.Components.Link

  require Logger

  data row, :struct
  data corrections, :map
  data predecessor, :struct
  data action_plan_suggestion, :list
  data action_plan, :list
  data complete, :boolean
  data tenants, :list
  data tracers, :list
  data supervisors, :list

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       tenants:
         Enum.filter(
           TenantContext.list_tenants(),
           &authorized?(Case, :create, get_auth(socket), tenant: &1)
         )
     )}
  end

  @impl Phoenix.LiveView
  def handle_params(%{"id" => id}, _uri, socket) do
    row =
      id
      |> ImportContext.get_row!()
      |> Repo.preload(import: [], tenant: [])

    socket =
      cond do
        not authorized?(row, :update, get_auth(socket)) ->
          socket
          |> push_redirect(to: Routes.home_index_path(socket, :index))
          |> put_flash(:error, gettext("You are not authorized to do this action."))

        row.status != :pending ->
          socket
          |> push_redirect(to: Routes.row_show_path(socket, :show, row))
          |> put_flash(:error, gettext("This row is already resolved."))

        true ->
          Phoenix.PubSub.subscribe(Hygeia.PubSub, "rows:#{id}")

          socket =
            assign(socket,
              page_title:
                "#{row.uuid} - #{Type.translate(row.import.type)} / #{HygeiaCldr.DateTime.to_string!(row.import.inserted_at)} - #{gettext("Import")} - #{gettext("Inbox")}"
            )

          load_data(socket, row)
      end

    {:noreply, socket}
  end

  @impl Phoenix.LiveView
  def handle_info({:updated, %Row{} = row, _version}, socket) do
    {:noreply, load_data(socket, row)}
  end

  def handle_info({:deleted, %Row{import_uuid: import_uuid}, _version}, socket) do
    {:noreply, redirect(socket, to: Routes.import_show_path(socket, :show, import_uuid))}
  end

  def handle_info(_other, socket), do: {:noreply, socket}

  @impl Phoenix.LiveView
  def handle_event("discard", _params, socket) do
    {:ok, row} = ImportContext.update_row(socket.assigns.row, %{status: :discarded})

    {:noreply, push_redirect(socket, to: Routes.row_show_path(socket, :show, row))}
  end

  def handle_event("save_corrections", %{"corrections" => corrections} = _params, socket) do
    {:ok, row} = ImportContext.update_row(socket.assigns.row, %{corrected: corrections})

    {:noreply, load_data(socket, row)}
  end

  def handle_event(
        "choose_tenant",
        %{"choose_tenant" => %{"index" => index, "tenant_uuid" => tenant_uuid}} = _params,
        socket
      ) do
    patch_action_plan(socket, index, fn %Action.ChooseTenant{} = action ->
      %Action.ChooseTenant{
        action
        | tenant: Enum.find(socket.assigns.tenants, &(&1.uuid == tenant_uuid))
      }
    end)
  end

  def handle_event(
        "select_person",
        %{"subject" => index, "uuid" => person_uuid} = _params,
        socket
      ) do
    person = CaseContext.get_person!(person_uuid)

    unless authorized?(person, :details, get_auth(socket)) do
      raise "unauthorized"
    end

    patch_action_plan(socket, index, fn %Action.SelectCase{} = action ->
      %Action.SelectCase{action | person: person, case: nil}
    end)
  end

  def handle_event("select_person", %{"subject" => index, "value" => ""} = _params, socket) do
    patch_action_plan(socket, index, fn %Action.SelectCase{} = action ->
      %Action.SelectCase{action | person: nil, case: nil}
    end)
  end

  def handle_event(
        "patch_assignee",
        %{
          "patch_assignee" => %{
            "tracer_uuid" => tracer_uuid,
            "supervisor_uuid" => supervisor_uuid,
            "index" => index
          }
        } = _params,
        socket
      ) do
    patch_action_plan(socket, index, fn %Action.PatchAssignee{} = action ->
      %Action.PatchAssignee{action | tracer_uuid: tracer_uuid, supervisor_uuid: supervisor_uuid}
    end)
  end

  def handle_event(
        "patch_status",
        %{"patch_status" => %{"status" => status, "index" => index}} = _params,
        socket
      ) do
    {:ok, status} = Case.Status.cast(status)

    patch_action_plan(socket, index, fn %Action.PatchStatus{} = action ->
      %Action.PatchStatus{action | status: status}
    end)
  end

  def handle_event(
        "select_case",
        %{"subject" => index, "uuid" => case_uuid} = _params,
        socket
      ) do
    case =
      case_uuid
      |> CaseContext.get_case!()
      |> Repo.preload(:person)

    unless authorized?(case, :details, get_auth(socket)) do
      raise "unauthorized"
    end

    patch_action_plan(socket, index, fn %Action.SelectCase{} = action ->
      %Action.SelectCase{action | person: case.person, case: case}
    end)
  end

  def handle_event("select_case", %{"subject" => index, "value" => ""} = _params, socket) do
    patch_action_plan(socket, index, fn %Action.SelectCase{} = action ->
      %Action.SelectCase{action | person: nil, case: nil}
    end)
  end

  def handle_event("execute", params, socket) do
    socket.assigns.action_plan
    |> Planner.execute(socket.assigns.row)
    |> case do
      {:ok, %{row: row}} ->
        if params["next"] do
          {:noreply,
           push_redirect(socket,
             to: Routes.row_apply_next_pending_path(socket, :apply_next_pending, row.import_uuid)
           )}
        else
          {:noreply, push_redirect(socket, to: Routes.row_show_path(socket, :show, row))}
        end

      {:error, reason} ->
        Logger.warn("""
        Import Execute failed with reason:
        #{inspect(reason, pretty: true)}
        """)

        Sentry.capture_message("""
        Import Execute failed with reason:
        #{inspect(reason, pretty: true)}
        """)

        {:noreply, put_flash(socket, :error, gettext("Execute failed, contact a Super User"))}
    end
  end

  defp patch_action_plan(socket, index, callback) when is_binary(index) do
    {index, ""} = Integer.parse(index)

    patch_action_plan(socket, index, callback)
  end

  defp patch_action_plan(socket, index, callback) do
    fixed_steps =
      socket.assigns.action_plan
      |> Enum.slice(0, index + 1)
      |> List.update_at(index, callback)

    {complete, action_plan_suggestion} =
      Planner.generate_action_plan_suggestion(socket.assigns.row, fixed_steps)

    action_plan = Enum.map(action_plan_suggestion, &elem(&1, 1))

    {:noreply,
     assign(socket,
       action_plan_suggestion: action_plan_suggestion,
       complete: complete,
       action_plan: action_plan
     )}
  end

  defp load_data(socket, row) do
    row = Repo.preload(row, import: [], tenant: [])
    predecessor = ImportContext.get_row_predecessor(row)

    {complete, action_plan_suggestion} = Planner.generate_action_plan_suggestion(row)
    action_plan = Enum.map(action_plan_suggestion, &elem(&1, 1))

    assign(socket,
      row: row,
      corrections: row.corrected || row.data,
      predecessor: predecessor,
      action_plan_suggestion: action_plan_suggestion,
      action_plan: action_plan,
      complete: complete,
      tracers: get_users(action_plan, :tracer),
      supervisors: get_users(action_plan, :supervisor)
    )
  end

  defp get_users(action_plan, type) do
    if Enum.any?(action_plan, &match?(%Action.PatchAssignee{}, &1)) do
      %Action.ChooseTenant{tenant: tenant} =
        Enum.find(action_plan, &match?(%Action.ChooseTenant{}, &1))

      UserContext.list_users_with_role(type, [tenant])
    else
      nil
    end
  end

  defp user_name(users, uuid)
  defp user_name(_users, nil), do: gettext("Case Administration")
  defp user_name(_users, ""), do: gettext("Case Administration")

  defp user_name(users, uuid) do
    %UserContext.User{display_name: display_name} =
      Enum.find(users, &match?(%UserContext.User{uuid: ^uuid}, &1))

    display_name
  end
end
