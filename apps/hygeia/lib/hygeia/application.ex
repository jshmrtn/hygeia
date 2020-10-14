defmodule Hygeia.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      # Start the Ecto repository
      Hygeia.Repo,
      # Start the PubSub system
      {Phoenix.PubSub, name: Hygeia.PubSub}
      # Start a worker by calling: Hygeia.Worker.start_link(arg)
      # {Hygeia.Worker, arg}
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: Hygeia.Supervisor)
  end
end
