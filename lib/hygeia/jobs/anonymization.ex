defmodule Hygeia.Jobs.Anonymization do
  @moduledoc """
  Anonimize persons and cases that are older than 2 years or have reidentification date older than 2 years.
  """

  use GenServer

  alias Hygeia.CaseContext
  alias Hygeia.Helpers.Versioning
  alias Hygeia.Repo

  require Logger

  case Mix.env() do
    :dev -> @default_refresh_interval_ms :timer.minutes(1)
    _env -> @default_refresh_interval_ms :timer.minutes(30)
  end

  {threshold_amount, threshold_unit} = Application.compile_env!(:hygeia, [__MODULE__, :threshold])
  @threshold_amount threshold_amount
  @threshold_unit threshold_unit

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
    {:ok, n_cases} =
      anonymize(
        CaseContext.list_cases_for_anonymization_query({@threshold_amount, @threshold_unit}),
        &CaseContext.anonymize_case/1
      )

    {:ok, n_people} =
      anonymize(
        CaseContext.list_people_for_anonymization_query({@threshold_amount, @threshold_unit}),
        &CaseContext.anonymize_person/1
      )

    Logger.info("Anonymization job: cases anonymized: #{n_cases}, people anonymized: #{n_people}")

    {:noreply, nil}
  end

  defp anonymize(query, anonymization_function) do
    {:ok, _length} =
      Repo.transaction(
        fn ->
          query
          |> Repo.stream()
          |> Task.async_stream(
            fn entry ->
              Versioning.put_originator(:noone)
              Versioning.put_origin(:anonymization_job)

              anonymization_function.(entry)
            end,
            ordered: false
          )
          |> Enum.count()
        end,
        timeout: :infinity
      )
  end
end
