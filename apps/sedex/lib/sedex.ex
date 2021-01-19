defmodule Sedex do
  @moduledoc """
  Sedex Interface
  """

  import Sedex.Schema

  alias Sedex.Schema.ECH009010

  require Sedex.Schema.ECH009010

  @type envelope :: %{
          :message_id => String.t(),
          :message_type => 0..2_699_999,
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

  @spec send(
          files :: %{required(filename :: String.t()) => iodata() | Enumerable.t()},
          sender_name :: String.t(),
          envelope :: envelope()
        ) :: :ok
  def send(
        files,
        sender_name,
        %{message_id: message_id, event_date: event_date} = envelope
      ) do
    files = prepare_files(files, sender_name, event_date)

    {:ok, {'mem', zip_binary}} = :zip.create('mem', files, [:memory])

    {:ok, xml} =
      envelope
      |> envelope_record()
      |> ECH009010.write()

    xml = ~S(<?xml version="1.0" encoding="utf-8"?>) <> xml

    :ok = storage().store("outbox", "data_#{message_id}.zip", zip_binary)

    :ok = storage().store("outbox", "envl_#{message_id}.xml", xml)

    :ok
  end

  defp prepare_files(files, sender_name, event_date) do
    files
    |> Enum.map(&normalize_file_content/1)
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

  @spec storage :: Sedex.Storage.t()
  defp storage,
    do:
      :sedex
      |> Application.get_env(Sedex.Storage, [])
      |> Keyword.get(:adapter, Sedex.Storage.Filesystem)
end
