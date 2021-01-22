# credo:disable-for-this-file Credo.Check.Warning.LeakyEnvironment
defmodule SedexTest do
  @moduledoc false

  use ExUnit.Case

  alias Sedex.Schema.ECH009010
  alias Sedex.Storage.Filesystem

  require Sedex.Schema.ECH009010

  @public_key_path Application.app_dir(:sedex, "priv/test/public.pem")

  [public_key] =
    @public_key_path
    |> File.read!()
    |> :public_key.pem_decode()

  @public_key :public_key.pem_entry_decode(public_key)

  @private_key_path Application.app_dir(:sedex, "priv/test/private.pem")

  @example_receipt :sedex
                   |> Application.app_dir("priv/test/example_receipt.xml")
                   |> File.read!()

  @example_receipt_name "receipt__ID_349C1EFE88C6FE4D.xml"
  @example_receipt_id "349C1EFE88C6FE4D"

  doctest Sedex

  setup do
    File.rm_rf!(Filesystem.base_path())

    on_exit(fn ->
      File.rm_rf!(Filesystem.base_path())
    end)

    :ok
  end

  describe "send/4" do
    test "creates files" do
      message_id = random_id()
      message_id_charlist = String.to_charlist(message_id)

      event_date = ~U[2021-01-21 14:04:25.224215Z]

      assert :ok =
               Sedex.send(
                 %{"foo.csv" => Stream.take(Stream.cycle(["foo"]), 1)},
                 "SG",
                 %{
                   message_id: message_id,
                   message_type: "1150",
                   message_class: 0,
                   sender_id: "***REMOVED***",
                   recipient_id: ["***REMOVED***"],
                   event_date: event_date
                 },
                 @public_key
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

      assert {:ok,
              [
                {'SG_1611237865_foo.csv.enc', csv_content_encrypted},
                {'SG_1611237865_key.enc', key_encrypted}
              ]} = data_path |> String.to_charlist() |> :zip.extract([:memory])

      data_enc_path = Briefly.create!()
      data_path = Briefly.create!()
      key_enc_path = Briefly.create!()
      key_path = Briefly.create!()

      File.write!(data_enc_path, csv_content_encrypted)
      File.write!(key_enc_path, key_encrypted)

      assert {_stderr, 0} =
               System.cmd(
                 "openssl",
                 [
                   "rsautl",
                   "-decrypt",
                   "-inkey",
                   @private_key_path,
                   "-in",
                   key_enc_path,
                   "-out",
                   key_path
                 ],
                 stderr_to_stdout: true
               )

      assert {_stderr, 0} =
               System.cmd(
                 "openssl",
                 [
                   "enc",
                   "-d",
                   "-aes-256-cbc",
                   "-salt",
                   "-in",
                   data_enc_path,
                   "-out",
                   data_path,
                   "-pass",
                   "file:#{key_path}"
                 ],
                 stderr_to_stdout: true
               )

      assert "foo" = File.read!(data_path)
    end
  end

  describe "message_status/1" do
    test "reads status" do
      Filesystem.store(@example_receipt_name, "receipts", @example_receipt)

      assert {:ok, :message_correctly_transmitted, "Message successfully transmitted"} =
               Sedex.message_status(@example_receipt_id)
    end
  end

  describe "cleanup/1" do
    test "deletes files" do
      id = random_id()

      Filesystem.store("recv__ID_#{id}.xml", "receipts", "receipt")
      Filesystem.store("data_#{id}.csv", "outbox", "foo")

      assert :ok = Sedex.cleanup(id)

      refute File.exists?(Path.join(Filesystem.base_path(), "receipts/recv__ID_#{id}.xml"))
      refute File.exists?(Path.join(Filesystem.base_path(), "outbox/data_#{id}.csv"))
    end
  end

  defp random_id, do: 8 |> :crypto.strong_rand_bytes() |> Base.encode16()
end
