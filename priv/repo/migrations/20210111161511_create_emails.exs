# credo:disable-for-this-file Credo.Check.Readability.Specs
defmodule Hygeia.Repo.Migrations.CreateEmails do
  @moduledoc false

  use Hygeia, :migration

  alias Hygeia.CommunicationContext.Direction
  alias Hygeia.CommunicationContext.Email
  alias Hygeia.CommunicationContext.SMS
  alias Hygeia.Repo

  def up do
    Direction.create_type()
    Email.Status.create_type()
    SMS.Status.create_type()

    alter table(:tenants) do
      add :from_email, :string
    end

    # Requires manual fix for settings
    execute("""
    UPDATE tenants
    SET from_email = outgoing_mail_configuration->>'from_email'
    """)

    create table(:emails) do
      add :direction, Direction.type(), null: false
      add :status, Email.Status.type(), null: false
      add :message, :binary, null: false
      add :last_try, :utc_datetime_usec
      add :case_uuid, references(:cases, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:emails, [:case_uuid])
    create index(:emails, [:direction, :status, :last_try])

    create table(:sms) do
      add :direction, Direction.type(), null: false
      add :status, SMS.Status.type(), null: false
      add :message, :text, null: false
      add :number, :string, null: false
      add :delivery_receipt_id, :string, null: true
      add :case_uuid, references(:cases, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:sms, [:case_uuid])
    create index(:sms, [:direction, :status])

    create table(:notes) do
      add :note, :text, null: false
      add :case_uuid, references(:cases, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:notes, [:case_uuid])

    execute(&migrate_emails/0)

    execute("""
    INSERT INTO sms (uuid, direction, status, message, number, delivery_receipt_id, case_uuid, inserted_at, updated_at)
    SELECT
      protocol_entries.uuid,
      'outgoing',
      'success',
      protocol_entries.entry->>'text' AS message,
      protocol_entries.entry->>'delivery_receipt_id' AS delivery_receipt_id,
      (ARRAY_AGG(mobile_contact_methods->>'value'))[1] AS number,
      protocol_entries.case_uuid,
      protocol_entries.inserted_at,
      protocol_entries.updated_at
    FROM protocol_entries
    JOIN cases ON protocol_entries.case_uuid = cases.uuid
    JOIN people ON cases.person_uuid = people.uuid
    JOIN UNNEST(people.contact_methods) AS mobile_contact_methods
    ON mobile_contact_methods->>'type' = 'mobile'
    WHERE entry->>'__type__' = 'sms'
    GROUP BY protocol_entries.uuid
    HAVING NOT (ARRAY_AGG(mobile_contact_methods->>'value'))[1] IS NULL
    """)

    execute """
    INSERT INTO notes (uuid, note, case_uuid, inserted_at, updated_at)
    SELECT
      uuid,
      entry->>'note' AS note,
      case_uuid,
      inserted_at,
      updated_at
    FROM protocol_entries
    WHERE entry->>'__type__' = 'note'
    """

    execute("""
    UPDATE versions
    SET item_type = 'Email'
    WHERE item_id IN (
      SELECT
        uuid
      FROM protocol_entries
      WHERE entry->>'__type__' = 'email'
    )
    """)

    execute("""
    UPDATE versions
    SET item_type = 'SMS'
    WHERE item_id IN (
      SELECT
        uuid
      FROM protocol_entries
      WHERE entry->>'__type__' = 'sms'
    )
    """)

    execute("""
    UPDATE versions
    SET item_type = 'Note'
    WHERE item_id IN (
      SELECT
        uuid
      FROM protocol_entries
      WHERE entry->>'__type__' = 'note'
    )
    """)

    drop table(:protocol_entries)
  end

  defp migrate_emails do
    Repo.transaction(fn ->
      from(
        entry in "protocol_entries",
        join: case in "cases",
        on: entry.case_uuid == case.uuid,
        join: person in "people",
        on: case.person_uuid == person.uuid,
        join: email_contact_method in fragment("UNNEST(?)", person.contact_methods),
        on: fragment("?->>?", email_contact_method, "type") == "email",
        join: tenant in "tenants",
        on: case.tenant_uuid == tenant.uuid,
        select: {
          entry.uuid,
          fragment("?->>?", entry.entry, "subject"),
          fragment("?->>?", entry.entry, "body"),
          fragment("(ARRAY_AGG(?->>?))[1]", email_contact_method, "value"),
          fragment("(ARRAY_AGG(?))[1]", tenant.from_email),
          entry.case_uuid,
          entry.inserted_at,
          entry.updated_at
        },
        where: fragment("?->>?", entry.entry, "__type__") == "email",
        group_by: entry.uuid,
        having: not is_nil(fragment("(ARRAY_AGG(?->>?))[1]", email_contact_method, "value"))
      )
      |> Repo.stream()
      |> Stream.map(fn {uuid, subject, body, to_email, from_email, case_uuid, inserted_at,
                        updated_at} ->
        {:ok, string_message_id} = Ecto.UUID.load(uuid)

        message =
          :mimemail.encode(
            {"text", "plain",
             [
               {"Subject", subject},
               {"From", from_email},
               {"To", to_email},
               {"Auto-submitted", "yes"},
               {"X-Auto-Response-Suppress", "All"},
               {"Precedence", "auto_reply"},
               {"Date", Calendar.strftime(inserted_at, "%a, %-d %b %Y %X %z")},
               {"Message-ID", string_message_id}
             ], %{}, body},
            []
          )

        %{
          uuid: uuid,
          message: message,
          case_uuid: case_uuid,
          inserted_at: inserted_at,
          updated_at: updated_at,
          direction: "outgoing",
          status: "success"
        }
      end)
      |> Stream.chunk_every(1000)
      |> Enum.each(fn entries_chunk ->
        length = length(entries_chunk)
        {^length, _result} = Repo.insert_all("emails", entries_chunk)
      end)
    end)
  end
end
