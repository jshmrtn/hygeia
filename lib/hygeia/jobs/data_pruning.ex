defmodule Hygeia.Jobs.DataPruning do
  @moduledoc """
  Prune data
  """

  use GenServer
  use Hygeia, :context

  alias Hygeia.Helpers.Versioning

  @default_refresh_interval_ms :timer.hours(1)

  {threshold_amount, threshold_unit} = Application.compile_env!(:hygeia, [__MODULE__, :threshold])
  @threshold_amount threshold_amount
  @threshold_unit threshold_unit

  @spec start_link(otps :: Keyword.t()) :: GenServer.on_start()
  def start_link(opts),
    do:
      GenServer.start_link(__MODULE__, Keyword.take(opts, [:name, :interval_ms]),
        name: Keyword.fetch!(opts, :name)
      )

  @spec child_spec(opts :: Keyword.t()) :: Supervisor.child_spec()
  def child_spec(opts) do
    # credo:disable-for-next-line Credo.Check.Warning.UnsafeToAtom
    %{super(opts) | id: Module.concat(__MODULE__, Keyword.fetch!(opts, :name))}
  end

  @impl GenServer
  def init(opts) do
    Versioning.put_originator(:noone)
    Versioning.put_origin(:data_pruning)

    interval_ms = Keyword.get(opts, :interval_ms, @default_refresh_interval_ms)

    Process.send_after(self(), {:start_interval, interval_ms}, :rand.uniform(interval_ms))

    {:ok, Keyword.fetch!(opts, :name)}
  end

  @impl GenServer
  def handle_info({:start_interval, interval_ms}, type) do
    :timer.send_interval(interval_ms, :execute)
    send(self(), :execute)

    {:noreply, type}
  end

  def handle_info(:execute, type) do
    execute_prune(type)

    {:noreply, type}
  end

  defp execute_prune(:resource_view),
    do:
      Repo.delete_all(
        from resource_view in "resource_views",
          where: resource_view.time < ago(^@threshold_amount, ^@threshold_unit)
      )

  defp execute_prune(:inbox) do
    {:ok, _} =
      Ecto.Multi.new()
      |> Ecto.Multi.delete_all(
        :delete,
        from(import_row in "import_rows",
          where: import_row.inserted_at < ago(^@threshold_amount, ^@threshold_unit)
        )
      )
      |> Versioning.authenticate_multi()
      |> Hygeia.Repo.transaction(timeout: :infinity)

    :ok
  end

  defp execute_prune(:version) do
    {:ok, _} =
      Ecto.Multi.new()
      |> Ecto.Multi.delete_all(
        :delete,
        from(version in "versions",
          where:
            version.inserted_at < ago(^@threshold_amount, ^@threshold_unit) and
              version.item_table not in [
                "cases",
                "people",
                "auto_tracings",
                "hospitalizations",
                "notes",
                "possible_index_submissions",
                "premature_releases",
                "tests",
                "emails",
                "sms",
                "visits",
                "transmissions",
                "vaccination_shots",
                "vaccination_shot_validity",
                "affiliations"
              ]
        )
      )
      |> Ecto.Multi.update_all(
        :update,
        from(version in "versions",
          where:
            version.inserted_at < ago(^@threshold_amount, ^@threshold_unit) and
              version.item_table in [
                "cases",
                "people",
                "auto_tracings",
                "hospitalizations",
                "notes",
                "possible_index_submissions",
                "premature_releases",
                "tests",
                "emails",
                "sms",
                "visits",
                "transmissions",
                "vaccination_shots",
                "vaccination_shot_validity",
                "affiliations"
              ],
          update: [set: [item_changes: fragment(~S['{}'::jsonb])]]
        ),
        []
      )
      |> Hygeia.Repo.transaction(timeout: :infinity)

    :ok
  end
end
