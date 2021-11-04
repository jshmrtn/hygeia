defmodule Hygeia.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  case Mix.env() do
    :test -> @workers []
    _others -> @workers [Hygeia.SedexExport, Hygeia.SystemMessageContext.SystemMessageCache]
  end

  @impl Application
  @spec start(start_type :: Application.start_type(), start_args :: term()) ::
          {:ok, pid()} | {:ok, pid(), Application.state()} | {:error, reason :: term()}
  def start(_type, _args) do
    {:ok, _} = EctoBootMigration.migrate(:hygeia)

    Supervisor.start_link(
      [
        {Cluster.Supervisor,
         [
           cluster_strategy(),
           [name: HygeiaCluster.Cluster.Supervisor]
         ]},
        HygeiaIam,
        HygeiaTelemetry,
        # Start the Ecto repository
        Hygeia.Repo,
        # Start the PubSub system
        {Phoenix.PubSub, name: Hygeia.PubSub},
        # Postgres PubSub Relay
        Hygeia.PostgresPubSubRelay,
        # Other Workers
        Hygeia.Jobs.Supervisor,
        HygeiaWeb.SessionStorage.Storage,
        HygeiaWeb.Endpoint | @workers
      ],
      strategy: :one_for_one,
      name: Hygeia.Supervisor
    )
  end

  @impl Application
  def config_change(changed, _new, removed) do
    HygeiaWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  defp cluster_strategy do
    with {:ok, app_name} <- System.fetch_env("RELEASE_NAME"),
         {:ok, selector} <- System.fetch_env("KUBERNETES_POD_SELECTOR"),
         {:ok, namespace} <- System.fetch_env("KUBERNETES_NAMESPACE") do
      [
        k8s: [
          strategy: Cluster.Strategy.Kubernetes,
          config: [
            mode: :dns,
            kubernetes_node_basename: app_name,
            kubernetes_selector: selector,
            kubernetes_namespace: namespace,
            polling_interval: 10_000
          ]
        ]
      ]
    else
      :error ->
        [
          local: [
            strategy: Cluster.Strategy.Epmd,
            config: [hosts: [:"test1@127.0.0.1", :"test2@127.0.0.1"]]
          ]
        ]
    end
  end
end
