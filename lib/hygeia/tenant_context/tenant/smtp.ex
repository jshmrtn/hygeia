defmodule Hygeia.TenantContext.Tenant.Smtp do
  @moduledoc """
  Model for Smtp Outgoing Mail Configuration Schema
  """

  use Hygeia, :model

  import Ecto.Changeset

  alias __MODULE__.DKIM
  alias __MODULE__.Relay
  alias Mail.Message
  alias Mail.Parsers.RFC2822

  @type empty :: %__MODULE__{
          enable_relay: boolean,
          relay: Relay.t() | nil,
          enable_dkim: boolean,
          dkim: DKIM.t() | nil
        }

  @type t :: %__MODULE__{
          enable_relay: boolean,
          relay: Relay.t() | nil,
          enable_dkim: boolean,
          dkim: DKIM.t() | nil
        }

  embedded_schema do
    field :enable_relay, :boolean, default: false
    field :enable_dkim, :boolean, default: false

    embeds_one :relay, Relay, on_replace: :update
    embeds_one :dkim, DKIM, on_replace: :update
  end

  @doc false
  @spec changeset(
          smtp :: t | empty,
          attrs :: Hygeia.ecto_changeset_params()
        ) :: Changeset.t()
  def changeset(smtp, attrs) do
    smtp
    |> cast(attrs, [:enable_relay, :enable_dkim])
    |> validate_required([:enable_relay, :enable_dkim])
    |> maybe_cast_embed(:relay, :enable_relay)
    |> maybe_cast_embed(:dkim, :enable_dkim)
  end

  defp maybe_cast_embed(changeset, embed, enable) do
    if Changeset.fetch_field!(changeset, enable) == true do
      cast_embed(changeset, embed)
    else
      put_embed(changeset, embed, nil)
    end
  end

  @spec gen_smtp_options(smtp_config :: t(), recipient_email :: String.t()) :: Keyword.t()
  def gen_smtp_options(smtp_config, recipient_email)

  def gen_smtp_options(%__MODULE__{enable_relay: false}, recipient_email) do
    relay = recipient_email |> String.split("@") |> List.last()

    [
      relay: relay,
      port: 25,
      hostname: :hygeia |> Application.fetch_env!(__MODULE__) |> Keyword.fetch!(:sender_hostname)
    ]
  end

  def gen_smtp_options(
        %__MODULE__{enable_relay: true, relay: %{} = relay_config},
        _recipient_email
      ) do
    relay_config
    |> Map.take([:server, :port, :username, :password])
    |> Enum.map(fn
      {:server, value} -> {:relay, value}
      {key, value} -> {key, value}
    end)
  end

  defimpl Hygeia.EmailSender do
    alias Hygeia.CommunicationContext.Email
    alias Hygeia.TenantContext.Tenant.Smtp

    require Logger

    @spec send(configuration :: Smtp.t(), email :: Email.t()) ::
            Email.Status.t()
    def send(smtp_config, %Email{message: message}) do
      parsed_message = RFC2822.parse(message)

      from = Message.get_header(parsed_message, "from")
      to = Message.get_header(parsed_message, "to")

      from_mail =
        case from do
          address when is_binary(address) -> address
          {_name, address} when is_binary(address) -> address
        end

      # Currently only one recipient is supported
      [to_mail] =
        Enum.map(to, fn
          address when is_binary(address) -> address
          {_name, address} when is_binary(address) -> address
        end)

      send_options = Smtp.gen_smtp_options(smtp_config, to_mail)

      {from_mail, [to_mail], message}
      |> :gen_smtp_client.send_blocking(
        send_options ++
          [
            retries: 10,
            tls: [
              versions: [:tlsv1, :"tlsv1.1", :"tlsv1.2", :"tlsv1.3"],
              verify: :verify_peer,
              depth: 4,
              cacertfile: CAStore.file_path(),
              customize_hostname_check: [
                match_fun: :public_key.pkix_verify_hostname_match_fun(:https)
              ]
            ]
          ]
      )
      |> case do
        binary when is_binary(binary) -> :success
        {:error, :send, error} -> handle_error(error)
        {:error, :no_more_hosts, error} -> handle_error(error)
        {:error, :retries_exceeded, error} -> handle_error(error)
      end
    catch
      {type, _reason} = error when is_atom(type) -> handle_error(error)
    end

    defp handle_error({:permanent_failure, host, reason}) do
      Logger.warn("""
      Permanently failed to send Email via #{host}:
      #{inspect(reason)}
      """)

      :permanent_failure
    end

    defp handle_error({:permanent_failure, reason}) do
      Logger.warn("""
      Permanently failed to send Email:
      #{inspect(reason)}
      """)

      :permanent_failure
    end

    defp handle_error({type, host, reason}) do
      Logger.warn("""
      Temporary failed to send Email via #{host} (#{type}):
      #{inspect(reason)}
      """)

      :temporary_failure
    end

    defp handle_error({type, reason}) do
      Logger.warn("""
      Temporary failed to send Email (#{type}):
      #{inspect(reason)}
      """)

      :temporary_failure
    end
  end
end
