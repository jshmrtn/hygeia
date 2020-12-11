defmodule HygeiaHealth do
  @moduledoc """
  Health Checks
  """

  Module.register_attribute(__MODULE__, :checks, accumulate: true)

  @type check_result :: :ok | {:error, String.t()}

  @checks %PlugCheckup.Check{name: "DB", module: __MODULE__, function: :check_db}
  @spec check_db :: check_result
  def check_db do
    Hygeia.Repo.query("select 1", [])
    :ok
  rescue
    DBConnection.ConnectionError -> {:error, "connection error"}
  end

  @checks %PlugCheckup.Check{
    name: "DB Migrated",
    module: __MODULE__,
    function: :check_db_migrated
  }
  @spec check_db_migrated :: check_result
  def check_db_migrated do
    alias Ecto.Migrator

    Hygeia.Repo
    |> Migrator.migrations([Migrator.migrations_path(Hygeia.Repo)])
    |> Enum.reject(&match?({:up, _version, _name}, &1))
    |> case do
      [] -> :ok
      [_migration | _other_migrations] -> {:error, "migrations pending"}
    end
  rescue
    DBConnection.ConnectionError -> {:error, "connection error"}
  end

  @checks %PlugCheckup.Check{name: "IAM Config", module: __MODULE__, function: :check_iam_config}
  @spec check_iam_config :: check_result
  def check_iam_config do
    "zitadel"
    |> :oidcc.get_openid_provider_info()
    |> case do
      {:ok, %{ready: true}} -> :ok
      {:ok, %{ready: false}} -> {:error, "not ready"}
    end
  end

  @checks %PlugCheckup.Check{
    name: "IAM UserInfo Endpoint Reachable",
    module: __MODULE__,
    function: :check_iam_userinfo_reachable
  }
  @spec check_iam_userinfo_reachable :: check_result
  def check_iam_userinfo_reachable do
    "invalid"
    |> :oidcc.retrieve_user_info("zitadel")
    |> case do
      {:error, {:bad_status, %{status: 401}}} -> :ok
      {:error, _reason} -> {:error, :unexpected_response}
    end
  end

  @checks %PlugCheckup.Check{
    name: "IAM Token Endpoint Reachable",
    module: __MODULE__,
    function: :check_iam_token_reachable
  }
  @spec check_iam_token_reachable :: check_result
  def check_iam_token_reachable do
    "invalid"
    |> :oidcc.retrieve_and_validate_token("zitadel")
    |> case do
      {:error, {:http_error, 400, _body}} -> :ok
      {:error, _reason} -> {:error, :unexpected_response}
    end
  end

  @checks %PlugCheckup.Check{name: "SMTP", module: __MODULE__, function: :check_smtp}
  @spec check_smtp :: check_result
  def check_smtp do
    alias Hygeia.TenantContext
    alias Hygeia.TenantContext.Tenant
    alias Hygeia.TenantContext.Tenant.Smtp

    TenantContext.list_tenants()
    |> Enum.filter(&match?(%Tenant{outgoing_mail_configuration: %Smtp{}}, &1))
    |> Enum.map(fn %Tenant{
                     name: name,
                     outgoing_mail_configuration: %Smtp{server: server, hostname: hostname}
                   } ->
      {name, server, hostname || server}
    end)
    |> Enum.map(&smtp_reply/1)
    |> Enum.reject(&match?({_tenant, :ok}, &1))
    |> case do
      [] -> :ok
      [{tenant, {:error, reason}}] -> {:error, "#{tenant}: #{inspect(reason)}"}
    end
  end

  defp smtp_reply({tenant_name, server, hostname}) do
    alias Socket.Stream
    alias Socket.TCP

    with {:ok, socket} <- TCP.connect(server, 25, packet: :line),
         {:ok, _resp} <- Stream.recv(socket),
         :ok <- Stream.send(socket, "HELO #{hostname}\r\n"),
         {:ok, "250" <> _rest} <- Stream.recv(socket) do
      {tenant_name, :ok}
    else
      {:error, reason} -> {tenant_name, {:error, reason}}
    end
  end

  @spec checks :: [%PlugCheckup.Check{}]
  def checks, do: @checks
end
