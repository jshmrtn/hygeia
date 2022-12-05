defmodule HygeiaHealth do
  @moduledoc """
  Health Checks
  """

  require Logger

  Module.register_attribute(__MODULE__, :checks, accumulate: true)

  @type check_result :: :ok | {:error, String.t()}

  @checks %PlugCheckup.Check{name: "DB", module: __MODULE__, function: :check_db}
  @spec check_db :: check_result
  def check_db do
    Hygeia.Repo.query!("select 1", [])
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
      {:error, {:bad_status, %{status: 401}}} ->
        :ok

      {:error, reason} ->
        Logger.error("Unexpected Response: #{inspect(reason)}")
        {:error, :unexpected_response}
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
      {:error, {:http_error, 400, _body}} ->
        :ok

      {:error, reason} ->
        Logger.error("Unexpected Response: #{inspect(reason)}")
        {:error, :unexpected_response}
    end
  end

  @checks %PlugCheckup.Check{name: "SMTP", module: __MODULE__, function: :check_smtp}
  @spec check_smtp :: check_result
  def check_smtp do
    alias Hygeia.TenantContext
    alias Hygeia.TenantContext.Tenant
    alias Hygeia.TenantContext.Tenant.Smtp

    TenantContext.list_tenants()
    |> Enum.filter(&match?(%Tenant{outgoing_mail_configuration: %Smtp{relay: %Smtp.Relay{}}}, &1))
    |> Enum.map(fn %Tenant{
                     name: name,
                     outgoing_mail_configuration: %Smtp{
                       relay: %Smtp.Relay{server: server, hostname: hostname}
                     }
                   } ->
      {name, server, hostname || server}
    end)
    |> Enum.map(&smtp_reply/1)
    |> Enum.reject(&match?({_tenant, :ok}, &1))
    |> case do
      [] -> :ok
      [{tenant, {:error, reason}}] -> {:error, "#{tenant}: #{inspect(reason)}"}
    end
  rescue
    DBConnection.ConnectionError -> {:error, "connection error"}
  end

  @checks %PlugCheckup.Check{
    name: "Email Spool wait time",
    module: __MODULE__,
    function: :check_email_spool_wait
  }
  @spec check_email_spool_wait :: check_result
  def check_email_spool_wait do
    import Ecto.Query

    alias Hygeia.CommunicationContext
    alias Hygeia.Repo

    interval =
      Repo.one(
        from(email in CommunicationContext.Email,
          select:
            coalesce(
              avg(coalesce(email.last_try, fragment("NOW()")) - email.inserted_at),
              fragment("INTERVAL '0 seconds'")
            ),
          where: email.status == :in_progress
        )
      )

    if interval.secs > 600 do
      {:error, "queing for avg of #{interval.secs} secs"}
    else
      :ok
    end
  end

  defp smtp_reply({tenant_name, server, hostname}) do
    with {:ok, socket} <-
           :gen_tcp.connect(String.to_charlist(server), 25, [:binary, {:packet, :line}]),
         :ok <-
           (receive do
              {:tcp, ^socket, "220" <> _rest} -> :ok
            after
              500 -> {:error, :timeout}
            end),
         :ok <- :gen_tcp.send(socket, "HELO #{hostname}\r\n"),
         :ok <-
           (receive do
              {:tcp, ^socket, "250" <> _rest} -> :ok
            after
              500 -> {:error, :timeout}
            end),
         :ok <- :gen_tcp.close(socket) do
      {tenant_name, :ok}
    else
      {:error, reason} -> {tenant_name, {:error, reason}}
    end
  end

  for {name, description} <- [sedex_backup: "Sedex Backup", database_backup: "Database Backup"] do
    @checks %PlugCheckup.Check{
      name: description,
      module: __MODULE__,
      function: name
    }
    @spec unquote(name)() :: check_result()
    # credo:disable-for-next-line Credo.Check.Readability.Specs
    def unquote(name)() do
      with host when is_binary(host) <-
             Application.get_env(:hygeia, __MODULE__)[unquote(name)][:host],
           access_key_id when is_binary(access_key_id) <-
             Application.get_env(:hygeia, __MODULE__)[unquote(name)][:access_key_id],
           secret_access_key when is_binary(secret_access_key) <-
             Application.get_env(:hygeia, __MODULE__)[unquote(name)][:secret_access_key],
           bucket when is_binary(bucket) <-
             Application.get_env(:hygeia, __MODULE__)[unquote(name)][:bucket],
           path when is_binary(path) <-
             Application.get_env(:hygeia, __MODULE__)[unquote(name)][:path] do
        date =
          DateTime.utc_now()
          |> DateTime.add(-(60 * 60 * 12), :second)
          |> DateTime.to_date()

        check_s3_for_object_with_date(bucket, path, date,
          host: host,
          access_key_id: access_key_id,
          secret_access_key: secret_access_key
        )
      else
        nil -> {:error, "the health check is not configured correctly"}
      end
    end
  end

  defp check_s3_for_object_with_date(bucket, prefix, date, s3_config) do
    bucket
    |> ExAws.S3.list_objects(prefix: prefix)
    |> ExAws.request(s3_config)
    |> case do
      {:ok, %{body: %{contents: contents}, status_code: 200}} ->
        date_to_search = Date.to_iso8601(date)

        contents
        |> Enum.find(fn %{last_modified: last_modified} -> last_modified =~ date_to_search end)
        |> case do
          nil -> {:error, "backup for #{date_to_search} not found"}
          %{} -> :ok
        end

      {:error, reason} ->
        Logger.error("Could not check if backup was made: #{inspect(reason)}")
        {:error, "request error"}
    end
  end

  # Official Type is not correct
  # credo:disable-for-next-line Credo.Check.Warning.SpecWithStruct
  @spec checks :: [%PlugCheckup.Check{name: String.t(), module: module(), function: atom()}]
  def checks, do: @checks
end
