defmodule HygeiaWeb.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl Application
  def start(_type, _args) do
    Supervisor.start_link(
      [
        HygeiaWeb.SessionStorage.Storage,
        HygeiaWeb.Endpoint
      ],
      strategy: :one_for_one,
      name: HygeiaWeb.Supervisor
    )
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl Application
  def config_change(changed, _new, removed) do
    HygeiaWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
