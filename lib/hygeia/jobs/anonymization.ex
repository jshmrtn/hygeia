defmodule Hygeia.Jobs.Anonymization do
  @moduledoc """
  Anonimize persons and cases that are older than 2 years or have reidentification date older than 2 years.
  """

  use GenServer

  import Ecto.Query, only: [from: 2]

  alias Hygeia.CaseContext
  alias Hygeia.CaseContext.Case
  alias Hygeia.CaseContext.Person
  alias Hygeia.Helpers.Versioning
  alias Hygeia.Repo

  @default_refresh_interval_ms :timer.seconds(10)

  @spec start_link(otps :: Keyword.t()) :: GenServer.on_start()
  def start_link(opts),
    do:
      GenServer.start_link(__MODULE__, Keyword.take(opts, [:interval_ms]),
        name: Keyword.get(opts, :name, __MODULE__)
      )

  @impl GenServer
  def init(opts) do
    Versioning.put_originator(:noone)
    Versioning.put_origin(:anonymization_job)

    interval_ms = Keyword.get(opts, :interval_ms, @default_refresh_interval_ms)

    Process.send_after(self(), {:start_interval, interval_ms}, interval_ms)

    {:ok, nil}
  end

  @impl GenServer
  def handle_info({:start_interval, interval_ms}, state) do
    :timer.send_interval(interval_ms, :execute)
    send(self(), :execute)

    {:noreply, state}
  end

  def handle_info(:execute, _params) do
    {:ok, now} = DateTime.now("Etc/UTC")
    # 63072000 == 2 years in seconds
    datetime = DateTime.add(now, -5, :second)

    :ok = anonymize_cases(datetime)
    :ok = anonymize_persons(datetime)
    IO.puts("Anonymization performed")
    {:noreply, nil}
  end

  defp anonymize_cases(datetime) do
    date = DateTime.to_date(datetime)

    stream =
      Repo.stream(
        from(c in Case,
          where:
            (not c.redacted and c.inserted_at <= ^datetime) or c.reidentification_date <= ^date
        ),
        max_rows: 1000
      )

    {:ok, _any} =
      Repo.transaction(fn ->
        stream
        |> Enum.to_list()
        |> Enum.each(&CaseContext.redact_case/1)
      end)

    :ok
  end

  defp anonymize_persons(datetime) do
    date = DateTime.to_date(datetime)

    stream =
      Repo.stream(
        from(p in Person,
          where:
            (not p.redacted and p.inserted_at <= ^datetime) or p.reidentification_date <= ^date
        ),
        max_rows: 1000
      )

    {:ok, _any} =
      Repo.transaction(fn ->
        stream
        |> Enum.to_list()
        |> Enum.each(&CaseContext.redact_person/1)
      end)

    :ok
  end
end
