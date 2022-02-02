defmodule Hygeia.Jobs.DetectNoReactionCases do
  @moduledoc """
  Detect No Reaction Cases
  """

  use GenServer

  import Ecto.Query, only: [from: 2]

  alias Hygeia.AutoTracingContext
  alias Hygeia.AutoTracingContext.AutoTracing.Step
  alias Hygeia.CaseContext.Case
  alias Hygeia.Helpers.Versioning
  alias Hygeia.Repo

  @default_refresh_interval_ms :timer.minutes(5)

  @no_reaction_limit_amount 6
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
    completed_steps = Step.completed_steps()

    cases =
      Repo.all(
        from(
          case in Case,
          join: auto_tracing in assoc(case, :auto_tracing),
          where:
            auto_tracing.started_at <= ago(^@no_reaction_limit_amount, ^@no_reaction_limit_unit) and
              (is_nil(auto_tracing.last_completed_step) or
                 auto_tracing.last_completed_step not in ^completed_steps) and
              case.status not in [:done, :canceled] and
              not fragment("'no_contact_method' = ANY(?)", auto_tracing.unsolved_problems),
          preload: [auto_tracing: auto_tracing]
        )
      )

    Enum.each(cases, &add_problem_as_needed/1)
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
