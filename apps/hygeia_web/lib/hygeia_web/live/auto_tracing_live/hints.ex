defmodule HygeiaWeb.AutoTracingLive.Hints do
  @moduledoc false

  use HygeiaWeb, :surface_live_component

  prop auto_tracing, :map, required: true

  defp organise_problems(problems) do
    Enum.reduce(problems, [], fn problem, acc ->
      case hint(problem) do
        nil -> acc
        hint -> [hint] ++ acc
      end
    end)
  end

  defp hint(:phase_date_inconsistent) do
    pgettext(
      "Auto Tracing Hints",
      "The symptoms start date is too far back and will trigger an inspection."
    )
  end

  defp hint(_unknown), do: nil
end
