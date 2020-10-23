defmodule HygeiaWeb.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  alias HygeiaWeb.Router.Helpers, as: Routes

  @impl Application
  @spec start(start_type :: Application.start_type(), start_args :: term()) ::
          {:ok, pid()} | {:ok, pid(), Application.state()} | {:error, reason :: term()}
  def start(_type, _args) do
    :application.set_env(:oidcc, :cacertfile, :certifi.cacertfile())

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    [
      # Start the Endpoint (http/https)
      HygeiaWeb.Endpoint
      # Start a worker by calling: HygeiaWeb.Worker.start_link(arg)
      # {HygeiaWeb.Worker, arg}
    ]
    |> Supervisor.start_link(
      strategy: :one_for_one,
      name: HygeiaWeb.Supervisor
    )
    |> case do
      {:ok, pid} ->
        iam_config =
          :ueberauth
          |> Application.fetch_env!(UeberauthOIDC)
          |> Keyword.put_new(
            :local_endpoint,
            Routes.auth_url(HygeiaWeb.Endpoint, :callback, "oidc")
          )

        Application.put_env(:ueberauth, UeberauthOIDC, iam_config)

        UeberauthOIDC.init!()

        {:ok, pid}

      {:error, reason} ->
        {:error, reason}
    end
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
