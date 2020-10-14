defmodule HygeiaWeb.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl Application
  @spec start(start_type :: Application.start_type(), start_args :: term()) ::
          {:ok, pid()} | {:ok, pid(), Application.state()} | {:error, reason :: term()}
  def start(_type, _args) do
    children = [
      # Start the Endpoint (http/https)
      HygeiaWeb.Endpoint
      # Start a worker by calling: HygeiaWeb.Worker.start_link(arg)
      # {HygeiaWeb.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: HygeiaWeb.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl Application
  @spec config_change(changed, new, removed) :: :ok
        when changed: keyword(), new: keyword(), removed: [atom()]
  def config_change(changed, _new, removed) do
    HygeiaWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
