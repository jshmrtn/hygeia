defmodule Hygeia.Jobs.DetectNoReactionCases do
  @moduledoc """
  Detect No Reaction Cases
  """

  use GenServer

  import Ecto.Query, only: [from: 2]

  alias Hygeia.AutoTracingContext
  alias Hygeia.CaseContext.Case
  alias Hygeia.Helpers.Versioning
  alias Hygeia.Repo

  @default_refresh_interval_ms :timer.hours(1)

  @no_reaction_limit_amount 2
  @no_reaction_limit_unit "hour"

  @spec start_link(otps :: Keyword.t()) :: GenServer.on_start()
  def start_link(opts),
    do:
      GenServer.start_link(__MODULE__, Keyword.take(opts, [:interval_ms]),
        name: Keyword.get(opts, :name, __MODULE__)
      )

  @impl GenServer
  def init(opts) do
    Versioning.put_originator(:noone)
    Versioning.put_origin(:detect_no_reaction_cases_job)

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
    detect_no_reaction_cases()

    {:noreply, nil}
  end

  defp detect_no_reaction_cases do
    cases =
      Repo.all(
        from(
          case in Case,
          where:
            case.status == "first_contact" and
              case.updated_at <= ago(^@no_reaction_limit_amount, ^@no_reaction_limit_unit)
        )
      )

    Enum.each(cases, fn case -> add_problem_as_needed(Repo.preload(case, auto_tracing: [])) end)
  end

  defp add_problem_as_needed(%{auto_tracing: nil}), do: nil

  defp add_problem_as_needed(%{auto_tracing: auto_tracing}),
    do:
      {:ok, _auto_tracing} =
        AutoTracingContext.auto_tracing_add_problem(
          auto_tracing,
          :no_reaction
        )
end
