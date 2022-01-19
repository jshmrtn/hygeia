# credo:disable-for-this-file Credo.Check.Readability.Specs
defmodule Hygeia.Repo.Migrations.VaccinationValidityMaterializedView do
  @moduledoc false

  use Hygeia, :migration

  alias Hygeia.Repo.Migrations.CreateVaccinationShots
  alias Hygeia.Repo.Migrations.VaccinationValidityCaseInfluence

  case Code.ensure_compiled(CreateVaccinationShots) do
    {:module, CreateVaccinationShots} ->
      nil

    _other ->
      Code.require_file("20211230121753_create_vaccination_shots.exs", Path.dirname(__ENV__.file))
  end

  case Code.ensure_compiled(VaccinationValidityCaseInfluence) do
    {:module, VaccinationValidityCaseInfluence} ->
      nil

    _other ->
      Code.require_file(
        "20220117182843_vaccination_validity_case_influence.exs",
        Path.dirname(__ENV__.file)
      )
  end

  def up do
    drop unique_index(:statistics_vaccination_breakthroughs_per_day, [:tenant_uuid, :date])

    drop index(:statistics_vaccination_breakthroughs_per_day, [:tenant_uuid])
    drop index(:statistics_vaccination_breakthroughs_per_day, [:date])

    execute("""
    DROP
      MATERIALIZED VIEW statistics_vaccination_breakthroughs_per_day
    """)

    execute("""
    DROP
      VIEW vaccination_shot_validity;
    """)

    execute("""
    CREATE
    MATERIALIZED VIEW vaccination_shot_validity
      AS #{VaccinationValidityCaseInfluence.vaccination_shot_validity_up_query()}
    """)

    create unique_index(:vaccination_shot_validity, [:vaccination_shot_uuid, :range])

    create index(:vaccination_shot_validity, [:vaccination_shot_uuid])
    create index(:vaccination_shot_validity, [:range])
    create index(:vaccination_shot_validity, [:person_uuid])

    execute(CreateVaccinationShots.statistics_vaccination_breakthroughs_per_day_up_sql())

    create unique_index(:statistics_vaccination_breakthroughs_per_day, [:tenant_uuid, :date])

    create index(:statistics_vaccination_breakthroughs_per_day, [:tenant_uuid])
    create index(:statistics_vaccination_breakthroughs_per_day, [:date])
  end
end
