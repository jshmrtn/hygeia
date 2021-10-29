# credo:disable-for-this-file Credo.Check.Readability.Specs
defmodule Hygeia.Repo.Migrations.TenantContactMethod do
  @moduledoc false

  use Hygeia, :migration

  def change do
    alter table(:tenants) do
      add :contact_phone, :string
      add :contact_email, :string
    end

    execute(fn ->
      :ok = run_authentication(repo(), origin: :migration, originator: :noone)
    end)

    execute(
      """
      UPDATE tenants
      SET
        contact_email = from_email,
        contact_phone = CASE
          WHEN country = 'CH' AND subdivision = 'AI' THEN '+41 71 521 26 10'
          WHEN country = 'CH' AND subdivision = 'AR' THEN '+41 71 521 26 10'
          WHEN country = 'CH' AND subdivision = 'SG' THEN '+41 71 521 26 10'
        END
      """,
      &noop/0
    )
  end

  defp noop, do: :ok
end
