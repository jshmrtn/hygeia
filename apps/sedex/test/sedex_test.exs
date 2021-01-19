defmodule SedexTest do
  @moduledoc false

  use ExUnit.Case

  alias Sedex.Schema.ECH009010
  alias Sedex.Storage.Filesystem

  require Sedex.Schema.ECH009010

  doctest Sedex

  setup do
    File.rm_rf!(Filesystem.base_path())

    on_exit(fn ->
      File.rm_rf!(Filesystem.base_path())
    end)

    :ok
  end

  test "creates files" do
    message_id = random_id()
    message_id_charlist = String.to_charlist(message_id)

    event_date = ~U[2021-01-21 14:04:25.224215Z]

    assert :ok =
             Sedex.send(
               %{"foo.csv" => Stream.take(Stream.cycle(["foo"]), 10)},
               "SG",
               %{
                 message_id: message_id,
                 message_type: "1150",
                 message_class: 0,
                 sender_id: "***REMOVED***",
                 recipient_id: ["***REMOVED***"],
                 event_date: event_date
               }
             )

    envelope_path = Path.join(Filesystem.base_path(), "outbox/envl_#{message_id}.xml")
    data_path = Path.join(Filesystem.base_path(), "outbox/data_#{message_id}.zip")

    assert File.exists?(envelope_path)
    assert File.exists?(data_path)

    assert {:ok, envelope_record, []} = ECH009010.read(File.read!(envelope_path))

    assert [
             anyAttribs: [
               {{'schemaLocation', 'http://www.w3.org/2001/XMLSchema-instance'},
                'http://www.ech.ch/xmlns/eCH-0090/1 schema.xsd'}
             ],
             version: '1.0',
             messageId: ^message_id_charlist,
             messageType: '1150',
             messageClass: 0,
             referenceMessageId: :undefined,
             senderId: '***REMOVED***',
             recipientId: ['***REMOVED***'],
             eventDate: '2021-01-21T14:04:25.224215Z',
             messageDate: [?2, ?0 | _rest] = _message_date,
             loopback: :undefined,
             testData: :undefined
           ] = ECH009010.envelopeType(envelope_record)

    assert {:ok, [{'SG_1611237865_foo.csv', "foofoofoofoofoofoofoofoofoofoo"}]} =
             data_path |> String.to_charlist() |> :zip.extract([:memory])
  end

  defp random_id, do: 8 |> :crypto.strong_rand_bytes() |> Base.encode16()
end
