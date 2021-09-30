defmodule HygeiaIam.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl Application
  def start(_type, _args) do
    for {provider, config} <- Application.fetch_env!(:hygeia_iam, :providers) do
      :oidcc.add_openid_provider(
        Keyword.fetch!(config, :issuer_or_config_endpoint),
        Keyword.fetch!(config, :local_endpoint),
        config |> Map.new() |> Map.put_new(:id, Atom.to_string(provider))
      )
    end

    for {provider, _config} <- Application.fetch_env!(:hygeia_iam, :providers) do
      :ok = wait_for_config_retrieval(provider)
    end

    Supervisor.start_link([], strategy: :one_for_one, name: HygeiaIam.Supervisor)
  end

  defp wait_for_config_retrieval(provider) do
    provider
    |> Atom.to_string()
    |> :oidcc.get_openid_provider_info()
    |> case do
      {:ok, %{ready: false}} ->
        :undefined = get_error(provider)

        Process.sleep(100)
        wait_for_config_retrieval(provider)

      {:ok, %{ready: true}} ->
        :ok
    end
  end

  defp get_error(provider) do
    {:ok, pid} =
      provider
      |> Atom.to_string()
      |> :oidcc_openid_provider_mgr.get_openid_provider()

    {:ok, error} = :oidcc_openid_provider.get_error(pid)

    error
  end
end
