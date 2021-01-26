defmodule Sedex do
  @moduledoc """
  Sedex Interface
  """

  import Sedex.Schema

  alias Sedex.Schema.ECH009010
  alias Sedex.Schema.ECH009020

  require Sedex.Schema.ECH009010
  require Sedex.Schema.ECH009020

  @password_size 64
  @salt_size 8
  @key_size 32
  @iv_size 16
  @pbkdf1_hash :sha256
  @pbkdf1_hash_length 32

  @type envelope :: %{
          :message_id => String.t(),
          :message_type => String.t(),
          :message_class => non_neg_integer(),
          :sender_id => String.t(),
          :recipient_id => [String.t()],
          :event_date => DateTime.t()
        }

  @type receipt :: %{
          event_date: DateTime.t(),
          status_code: :ok | {:error, 200..500},
          status_info: String.t() | nil,
          message_id: String.t(),
          message_type: 0..2_699_999,
          message_class: non_neg_integer(),
          sender_id: String.t(),
          recipient_id: String.t()
        }

  @type status ::
          :message_correctly_transmitted
          | :invalid_envelope_syntax
          | :duplicate_message_id
          | :no_payload_found
          | :message_too_old
          | :message_expired
          | :unknown_sender_id
          | :unknown_recipient_id
          | :unknown_physical_sender_id
          | :invalid_message_type
          | :invalid_message_class
          | :not_allowed_to_send
          | :not_allowed_to_receive
          | :user_certificate_not_valid
          | :recipient_not_allowed_to_receive
          | :message_size_exceeds_limit
          | :network_error
          | :osci_hub_not_reachable
          | :folder_not_reachable
          | :logging_service_not_reachable
          | :authorization_service_not_reachable
          | :internal_error
          | :error_during_receiving
          | :message_successfully_sent
          | :message_expires_soon

  @spec send(
          files :: %{required(filename :: String.t()) => iodata() | Enumerable.t()},
          sender_name :: String.t(),
          envelope :: envelope(),
          public_key :: :public_key.public_key()
        ) :: :ok
  def send(
        files,
        sender_name,
        %{message_id: message_id, event_date: event_date} = envelope,
        public_key
      ) do
    files = prepare_files(files, sender_name, event_date, public_key)

    {:ok, {'mem', zip_binary}} = :zip.create('mem', files, [:memory])

    {:ok, xml} =
      envelope
      |> envelope_record()
      |> ECH009010.write()

    xml = ~S(<?xml version="1.0" encoding="utf-8"?>) <> xml

    :ok = storage().store("data_#{message_id}.zip", "outbox", zip_binary)

    :ok = storage().store("envl_#{message_id}.xml", "outbox", xml)

    :ok
  end

  @spec message_status(message_id :: String.t()) ::
          {:ok, status :: status(), message :: String.t()} | {:error, :not_found}
  # credo:disable-for-next-line Credo.Check.Refactor.ABCSize
  def message_status(message_id) do
    with {:ok, content} <- storage().read("receipt__ID_#{message_id}.xml", "receipts"),
         {:ok, ECH009020.receiptType(statusCode: '100', statusInfo: message), _rest} <-
           ECH009020.read(content) do
      {:ok, :message_correctly_transmitted, :erlang.list_to_binary(message)}
    else
      {:ok, ECH009020.receiptType(statusCode: '200', statusInfo: message), _rest} ->
        {:ok, :invalid_envelope_syntax, :erlang.list_to_binary(message)}

      {:ok, ECH009020.receiptType(statusCode: '201', statusInfo: message), _rest} ->
        {:ok, :duplicate_message_id, :erlang.list_to_binary(message)}

      {:ok, ECH009020.receiptType(statusCode: '202', statusInfo: message), _rest} ->
        {:ok, :no_payload_found, :erlang.list_to_binary(message)}

      {:ok, ECH009020.receiptType(statusCode: '203', statusInfo: message), _rest} ->
        {:ok, :message_too_old, :erlang.list_to_binary(message)}

      {:ok, ECH009020.receiptType(statusCode: '204', statusInfo: message), _rest} ->
        {:ok, :message_expired, :erlang.list_to_binary(message)}

      {:ok, ECH009020.receiptType(statusCode: '300', statusInfo: message), _rest} ->
        {:ok, :unknown_sender_id, :erlang.list_to_binary(message)}

      {:ok, ECH009020.receiptType(statusCode: '301', statusInfo: message), _rest} ->
        {:ok, :unknown_recipient_id, :erlang.list_to_binary(message)}

      {:ok, ECH009020.receiptType(statusCode: '302', statusInfo: message), _rest} ->
        {:ok, :unknown_physical_sender_id, :erlang.list_to_binary(message)}

      {:ok, ECH009020.receiptType(statusCode: '303', statusInfo: message), _rest} ->
        {:ok, :invalid_message_type, :erlang.list_to_binary(message)}

      {:ok, ECH009020.receiptType(statusCode: '304', statusInfo: message), _rest} ->
        {:ok, :invalid_message_class, :erlang.list_to_binary(message)}

      {:ok, ECH009020.receiptType(statusCode: '310', statusInfo: message), _rest} ->
        {:ok, :not_allowed_to_send, :erlang.list_to_binary(message)}

      {:ok, ECH009020.receiptType(statusCode: '311', statusInfo: message), _rest} ->
        {:ok, :not_allowed_to_receive, :erlang.list_to_binary(message)}

      {:ok, ECH009020.receiptType(statusCode: '312', statusInfo: message), _rest} ->
        {:ok, :user_certificate_not_valid, :erlang.list_to_binary(message)}

      {:ok, ECH009020.receiptType(statusCode: '313', statusInfo: message), _rest} ->
        {:ok, :recipient_not_allowed_to_receive, :erlang.list_to_binary(message)}

      {:ok, ECH009020.receiptType(statusCode: '330', statusInfo: message), _rest} ->
        {:ok, :message_size_exceeds_limit, :erlang.list_to_binary(message)}

      {:ok, ECH009020.receiptType(statusCode: '400', statusInfo: message), _rest} ->
        {:ok, :network_error, :erlang.list_to_binary(message)}

      {:ok, ECH009020.receiptType(statusCode: '401', statusInfo: message), _rest} ->
        {:ok, :osci_hub_not_reachable, :erlang.list_to_binary(message)}

      {:ok, ECH009020.receiptType(statusCode: '402', statusInfo: message), _rest} ->
        {:ok, :folder_not_reachable, :erlang.list_to_binary(message)}

      {:ok, ECH009020.receiptType(statusCode: '403', statusInfo: message), _rest} ->
        {:ok, :logging_service_not_reachable, :erlang.list_to_binary(message)}

      {:ok, ECH009020.receiptType(statusCode: '404', statusInfo: message), _rest} ->
        {:ok, :authorization_service_not_reachable, :erlang.list_to_binary(message)}

      {:ok, ECH009020.receiptType(statusCode: '500', statusInfo: message), _rest} ->
        {:ok, :internal_error, :erlang.list_to_binary(message)}

      {:ok, ECH009020.receiptType(statusCode: '501', statusInfo: message), _rest} ->
        {:ok, :error_during_receiving, :erlang.list_to_binary(message)}

      {:ok, ECH009020.receiptType(statusCode: '601', statusInfo: message), _rest} ->
        {:ok, :message_successfully_sent, :erlang.list_to_binary(message)}

      {:ok, ECH009020.receiptType(statusCode: '701', statusInfo: message), _rest} ->
        {:ok, :message_expires_soon, :erlang.list_to_binary(message)}

      {:error, :not_found} ->
        {:error, :not_found}
    end
  end

  @spec cleanup(id :: String.t()) :: :ok
  def cleanup(id) do
    for directory <- ["inbox", "outbox", "processed", "receipts", "working"] do
      :ok = storage().cleanup(directory, id)
    end

    :ok
  end

  defp prepare_files(files, sender_name, event_date, public_key) do
    <<password::binary-size(@password_size)>> = password()
    password = Base.encode16(password)
    <<salt::binary-size(@salt_size)>> = salt()

    password_encrypted = :public_key.encrypt_public(password, public_key)

    <<key::binary-size(@key_size), iv::binary-size(@iv_size)>> =
      pbkdf1_until_enough(password, salt, @key_size + @iv_size)

    files
    |> Enum.map(&normalize_file_content/1)
    |> Enum.map(&encrypt_file(&1, key, iv, salt))
    |> Enum.concat([{"key.enc", password_encrypted}])
    |> Enum.map(&normalize_file_name(&1, sender_name, event_date))
  end

  defp normalize_file_content({filename, binary}) when is_binary(binary), do: {filename, binary}

  defp normalize_file_content({filename, list}) when is_list(list),
    do: {filename, IO.iodata_to_binary(list)}

  defp normalize_file_content({filename, other}),
    do: {filename, other |> Enum.to_list() |> IO.iodata_to_binary()}

  defp normalize_file_name({filename, content}, sender_name, event_date),
    do:
      {String.to_charlist("#{sender_name}_#{DateTime.to_unix(event_date)}_#{filename}"), content}

  defp encrypt_file({filename, content}, key, iv, salt) do
    content = :jose_jwa_pkcs7.pad(content)

    content =
      "Salted__" <> salt <> :crypto.crypto_one_time(:aes_256_cbc, key, iv, content, encrypt: true)

    {filename <> ".enc", content}
  end

  defp envelope_record(
         %{
           message_id: message_id,
           message_type: message_type,
           message_class: message_class,
           sender_id: sender_id,
           recipient_id: recipient_id,
           event_date: event_date
         } = _envelope
       ),
       do:
         ECH009010.envelopeType(
           version: "1.0",
           anyAttribs: [
             {{'schemaLocation', 'http://www.w3.org/2001/XMLSchema-instance'},
              'http://www.ech.ch/xmlns/eCH-0090/1 schema.xsd'}
           ],
           messageId: message_id,
           messageType: message_type,
           messageClass: message_class,
           messageDate: DateTime.to_iso8601(DateTime.utc_now()),
           senderId: sender_id,
           recipientId: recipient_id,
           eventDate: DateTime.to_iso8601(event_date)
         )

  defp password, do: :crypto.strong_rand_bytes(@password_size)

  defp salt, do: :crypto.strong_rand_bytes(8)

  defp pbkdf1_until_enough(password, salt, length) do
    0
    |> Range.new(pbkdf1_iteration_count(length) - 1)
    |> Enum.reduce([], fn
      _i, acc ->
        {:ok, new_derived} =
          :jose_jwa_pkcs5.pbkdf1(
            @pbkdf1_hash,
            case acc do
              [] -> ""
              [last_derived | _rest_derived] -> last_derived
            end <> password,
            salt,
            1,
            @pbkdf1_hash_length
          )

        [new_derived | acc]
    end)
    |> Enum.reverse()
    |> Enum.join()
    |> :binary.part(0, length)
  end

  defp pbkdf1_iteration_count(length),
    do:
      length
      |> Kernel./(@pbkdf1_hash_length)
      |> Float.ceil()
      |> trunc()

  @spec storage :: Sedex.Storage.t()
  defp storage,
    do:
      :sedex
      |> Application.get_env(Sedex.Storage, [])
      |> Keyword.get(:adapter, Sedex.Storage.Filesystem)
end
