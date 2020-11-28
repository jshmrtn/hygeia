defmodule Hygeia.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl Application
  @spec start(start_type :: Application.start_type(), start_args :: term()) ::
          {:ok, pid()} | {:ok, pid(), Application.state()} | {:error, reason :: term()}
  def start(_type, _args) do
    {:ok, _} = EctoBootMigration.migrate(:hygeia)

    Supervisor.start_link(
      [
        # Start the Ecto repository
        Hygeia.Repo,
        # Start the PubSub system
        {Phoenix.PubSub, name: Hygeia.PubSub}
        # TODO: Re-enable
        # Hygeia.Jobs.Supervisor
      ],
      strategy: :one_for_one,
      name: Hygeia.Supervisor
    )
  end
end
