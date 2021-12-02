# credo:disable-for-this-file Credo.Check.Readability.Specs
defmodule Hygeia.Repo.Migrations.TenantLocation do
  @moduledoc false

  use Hygeia, :migration

  def change do
    execute(
      fn ->
        :ok = run_authentication(repo(), origin: :migration, originator: :noone)
      end,
      &noop/0
    )

    alter table(:tenants) do
      add :subdivision, :string
      add :country, :string
      remove :short_name, :string, null: true
    end

    execute(
      """
      UPDATE tenants
        SET
          subdivision = CASE
            WHEN name = 'Bundesland Baden-Württemberg' THEN 'BW'
            WHEN name = 'Bundesland Bayern' THEN 'BY'
            WHEN name = 'Bundesland Tirol' THEN '7'
            WHEN name = 'Bundesland Vorarlberg' THEN '8'
            WHEN name = 'Fürstentum Lichtenstein' THEN NULL
            WHEN name = 'Kanton Aargau' THEN 'AG'
            WHEN name = 'Kanton Appenzell Ausserrhoden' THEN 'AR'
            WHEN name = 'Kanton Appenzell Innerrhoden' THEN 'AI'
            WHEN name = 'Kanton Basel-Landschaft' THEN 'BL'
            WHEN name = 'Kanton Basel-Stadt' THEN 'BS'
            WHEN name = 'Kanton Bern' THEN 'BE'
            WHEN name = 'Kanton Fribourg' THEN 'FR'
            WHEN name = 'Kanton Freiburg' THEN 'FR'
            WHEN name = 'Kanton Genève' THEN 'GE'
            WHEN name = 'Kanton Genf' THEN 'GE'
            WHEN name = 'Kanton Glarus' THEN 'GL'
            WHEN name = 'Kanton Graubünden' THEN 'GR'
            WHEN name = 'Kanton Jura' THEN 'JU'
            WHEN name = 'Kanton Luzern' THEN 'LU'
            WHEN name = 'Kanton Neuchâtel' THEN 'NE'
            WHEN name = 'Kanton Neuenburg' THEN 'NE'
            WHEN name = 'Kanton Freiburg' THEN 'NE'
            WHEN name = 'Kanton Nidwalden' THEN 'NW'
            WHEN name = 'Kanton Obwalden' THEN 'OW'
            WHEN name = 'Kanton Schaffhausen' THEN 'SH'
            WHEN name = 'Kanton Schwyz' THEN 'SZ'
            WHEN name = 'Kanton Solothurn' THEN 'SO'
            WHEN name = 'Kanton St. Gallen' THEN 'SG'
            WHEN name = 'Kanton Sankt Gallen' THEN 'SG'
            WHEN name = 'Kanton Thurgau' THEN 'TG'
            WHEN name = 'Kanton Ticino' THEN 'TI'
            WHEN name = 'Kanton Tessin' THEN 'TI'
            WHEN name = 'Kanton Uri' THEN 'UR'
            WHEN name = 'Kanton Valais' THEN 'VS'
            WHEN name = 'Kanton Wallis' THEN 'VS'
            WHEN name = 'Kanton Vaud' THEN 'VD'
            WHEN name = 'Kanton Waadt' THEN 'VD'
            WHEN name = 'Kanton Zug' THEN 'ZG'
            WHEN name = 'Kanton Zürich' THEN 'ZH'
            ELSE NULL
          END,
          country = CASE
            WHEN name LIKE 'Kanton%' THEN 'CH'
            WHEN name = 'Bundesland Baden-Württemberg' THEN 'DE'
            WHEN name = 'Bundesland Bayern' THEN 'DE'
            WHEN name = 'Bundesland Tirol' THEN 'AT'
            WHEN name = 'Bundesland Vorarlberg' THEN 'AT'
            WHEN name = 'Fürstentum Lichtenstein' THEN 'LI'
            ELSE NULL
          END
      """,
      &noop/0
    )
  end
end
