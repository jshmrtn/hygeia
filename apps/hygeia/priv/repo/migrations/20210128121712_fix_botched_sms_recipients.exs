# credo:disable-for-this-file Credo.Check.Readability.Specs
defmodule Hygeia.Repo.Migrations.FixBotchedSmsRecipients do
  @moduledoc false

  # Migration apps/hygeia/priv/repo/migrations/20210111161511_create_emails.exs
  # Ordered the delivery_receipt_id & number fields wrong.
  # This migration switches them back.

  use Hygeia, :migration

  def change do
    execute("""
    UPDATE sms
    SET
        (delivery_receipt_id, number) = (number, delivery_receipt_id)
    WHERE
          delivery_receipt_id LIKE '+%' AND
          number NOT LIKE '+%'
    """)
  end
end
