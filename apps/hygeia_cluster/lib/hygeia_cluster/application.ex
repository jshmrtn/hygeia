defmodule HygeiaCluster.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl Application
  @spec start(start_type :: Application.start_type(), start_args :: term()) ::
          {:ok, pid()} | {:ok, pid(), Application.state()} | {:error, reason :: term()}
  def start(_type, _args) do
    strategy =
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

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    Supervisor.start_link(
      [
        {Cluster.Supervisor,
         [
           strategy,
           [name: HygeiaCluster.Cluster.Supervisor]
         ]}
      ],
      strategy: :one_for_one,
      name: HygeiaCluster.Supervisor
    )
  end
end
