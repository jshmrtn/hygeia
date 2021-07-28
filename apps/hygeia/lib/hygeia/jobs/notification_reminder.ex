defmodule Hygeia.Jobs.NotificationReminder do
  @moduledoc """
  Send Notification Reminder Emails
  """

  use GenServer

  import Ecto.Query, only: [from: 2]
  import HygeiaGettext

  alias Hygeia.CommunicationContext
  alias Hygeia.Helpers.Versioning
  alias Hygeia.NotificationContext
  alias Hygeia.Repo
  alias Hygeia.UserContext.User

  require Logger

  case Mix.env() do
    :dev -> @default_refresh_interval_ms :timer.minutes(5)
    _env -> @default_refresh_interval_ms :timer.hours(1)
  end

  @spec start_link(opts :: Keyword.t()) :: GenServer.on_start()
  def start_link(opts),
    do:
      GenServer.start_link(__MODULE__, Keyword.take(opts, [:view, :interval_ms]),
        name: Keyword.get(opts, :name, __MODULE__)
      )

  @impl GenServer
  def init(opts) do
    Versioning.put_originator(:noone)
    Versioning.put_origin(:email_sender)

    interval_ms = Keyword.get(opts, :interval_ms, @default_refresh_interval_ms)

    Process.send_after(self(), {:start_interval, interval_ms}, :rand.uniform(interval_ms))

    {:ok, nil}
  end

  @impl GenServer
  def handle_info({:start_interval, interval_ms}, state) do
    :timer.send_interval(interval_ms, :send)
    send(self(), :send)

    {:noreply, state}
  end

  def handle_info(:send, state) do
    execute_send()

    {:noreply, state}
  end

  def handle_info(_other, state), do: {:noreply, state}

  @impl GenServer
  def handle_cast(:send, state) do
    execute_send()

    {:noreply, state}
  end

  @spec send(server :: GenServer.server()) :: :ok
  def send(server) do
    GenServer.cast(server, :send)
  end

  @spec execute_send :: :ok
  defp execute_send do
    {:ok, emails} =
      Repo.transaction(
        fn ->
          # Find Users that should receive an email
          NotificationContext.list_and_lock_users_with_pending_notification_reminders()
          # Mark all Notifications as notified
          |> Enum.reduce(Ecto.Multi.new(), &mark_read/2)
          |> Versioning.authenticate_multi()
          |> Hygeia.Repo.transaction()
          |> case do
            {:ok, results} -> results
            {:error, reason} -> Repo.rollback(reason)
            {:error, _operation, reason, _others} -> Repo.rollback(reason)
          end
          # Remove Versioning Artifact
          |> Enum.reject(&match?({:set_versioning_variables, _result}, &1))
          # Send Email
          |> Enum.reduce(Ecto.Multi.new(), &send_notification/2)
          |> Versioning.authenticate_multi()
          |> Hygeia.Repo.transaction()
          |> case do
            {:ok, results} -> results
            {:error, reason} -> Repo.rollback(reason)
            {:error, _operation, reason, _others} -> Repo.rollback(reason)
          end
          # Remove Versioning Artifact
          |> Enum.reject(&match?({:set_versioning_variables, _result}, &1))
          |> Keyword.values()
        end,
        timeout: :infinity
      )

    Logger.info("Sent #{length(emails)} notification emails")

    :ok
  end

  @spec mark_read(user :: User.t(), multi :: Ecto.Multi.t()) :: Ecto.Multi.t()
  defp mark_read(user, multi) do
    Ecto.Multi.update_all(
      multi,
      user,
      from(notification in Ecto.assoc(user, :notifications),
        select: fragment("?->>'__type__'", notification.body),
        where: not notification.read and not notification.notified
      ),
      set: [notified: true]
    )
  end

  @spec send_notification(
          result :: {user :: User.t(), types :: {pos_integer, [String.t()]}},
          multi :: Ecto.Multi.t()
        ) :: Ecto.Multi.t()
  defp send_notification({user, {total_count, types}}, multi) do
    Ecto.Multi.run(multi, user, fn _repo, _others ->
      CommunicationContext.create_outgoing_email(
        user,
        ngettext("%{count} New Notification", "%{count} New Notifications", total_count,
          count: total_count
        ),
        email_message(user, types)
      )
    end)
  end

  @spec email_message(user :: User.t(), types :: %{String.t() => pos_integer()}) :: String.t()
  defp email_message(%User{display_name: display_name} = _user, types) do
    # TODO: Get Local from User
    HygeiaCldr.put_locale("de-CH")
    Gettext.put_locale(HygeiaCldr.get_locale().gettext_locale_name || "de")

    totals_text =
      types
      |> Enum.reduce(%{}, fn type, acc ->
        Map.update(acc, type, 1, &(&1 + 1))
      end)
      |> Enum.map(fn {type, count} ->
        "* #{translate_type(type)} - #{HygeiaCldr.Number.to_string!(count)}"
      end)
      |> Enum.join("\n")

    gettext(
      """
      Hi %{name},

      There's new notifications available on Hygeia for you:
      %{totals}

      Best,
      Hygeia
      """,
      name: display_name,
      totals: totals_text
    )
  end

  @spec translate_type(String.t()) :: String.t()
  defp translate_type(type)
  defp translate_type("case_assignee"), do: pgettext("Notification Type", "Case Assignee Changed")
  defp translate_type("email_send_failed"), do: pgettext("Notification Type", "Email Send Failed")

  defp translate_type("self_service_help_request"),
    do: pgettext("Notification Type", "Self Service Help Request")

  defp translate_type("unchanged_case"), do: pgettext("Notification Type", "Unchanged Case")

  defp translate_type(type) do
    Logger.warn("Unknown Notification Type #{inspect(type)}")
    type
  end
end
