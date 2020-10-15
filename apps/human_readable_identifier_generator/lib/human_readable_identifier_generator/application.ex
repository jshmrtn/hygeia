defmodule HumanReadableIdentifierGenerator.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl Application
  @spec start(start_type :: Application.start_type(), start_args :: term()) ::
          {:ok, pid()} | {:ok, pid(), Application.state()} | {:error, reason :: term()}
  def start(_type, _args) do
    # List all child processes to be supervised
    children = [
      # Starts a worker by calling: HumanReadableIdentifierGenerator.Worker.start_link(arg)
      # {HumanReadableIdentifierGenerator.Worker, arg}
      HumanReadableIdentifierGenerator.Storage
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: HumanReadableIdentifierGenerator.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
