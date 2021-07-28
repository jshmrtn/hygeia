defmodule Hygeia.Jobs.DetectUnchangedCases do
  @moduledoc """
  Detect Unchanged Cases
  """

  use GenServer

  import Ecto.Query, only: [from: 2]

  alias Hygeia.CaseContext.Case
  alias Hygeia.Helpers.Versioning
  alias Hygeia.NotificationContext
  alias Hygeia.Repo
  alias Hygeia.UserContext

  @default_refresh_interval_ms :timer.hours(1)

  @spec start_link(otps :: Keyword.t()) :: GenServer.on_start()
  def start_link(opts),
    do:
      GenServer.start_link(__MODULE__, Keyword.take(opts, [:interval_ms]),
        name: Keyword.get(opts, :name, __MODULE__)
      )

  @impl GenServer
  def init(opts) do
    Versioning.put_originator(:noone)
    Versioning.put_origin(:detect_unchanged_cases_job)

    interval_ms = Keyword.get(opts, :interval_ms, @default_refresh_interval_ms)

    Process.send_after(self(), {:start_interval, interval_ms}, :rand.uniform(interval_ms))

    {:ok, nil}
  end

  @impl GenServer
  def handle_info({:start_interval, interval_ms}, state) do
    :timer.send_interval(interval_ms, :execute)
    send(self(), :execute)

    {:noreply, state}
  end

  def handle_info(:execute, _params) do
    detect_unchanged_cases()

    {:noreply, nil}
  end

  defp detect_unchanged_cases do
    cases =
      Repo.all(
        from(
          case in Case,
          where:
            case.status == "first_contact" and
              case.updated_at <=
                fragment("CURRENT_TIMESTAMP - INTERVAL '3 day'")
        )
      )

    Enum.each(cases, fn case -> notify_as_needed(case) end)
  end

  defp notify_as_needed(%{tracer_uuid: nil}), do: nil

  defp notify_as_needed(case) do
    user = UserContext.get_user!(case.tracer_uuid)

    if is_nil(NotificationContext.get_notification_by_type_and_case("unchanged_case", case)) do
      NotificationContext.create_notification(user, %{
        body: %{uuid: Ecto.UUID.generate(), __type__: :unchanged_case, case_uuid: case.uuid}
      })
    end
  end
end
