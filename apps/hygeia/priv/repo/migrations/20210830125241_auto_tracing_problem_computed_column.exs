# credo:disable-for-this-file Credo.Check.Readability.Specs
defmodule Hygeia.Repo.Migrations.AutoTracingProblemComputedColumn do
  @moduledoc false

  use Hygeia, :migration

  alias Hygeia.AutoTracingContext.AutoTracing.Problem

  def change do
    execute(
      """
      CREATE FUNCTION
        array_disjoint(a anyarray, b anyarray)
        RETURNS anyarray
        AS '
          SELECT
            ARRAY(
              SELECT
                UNNEST(a)
              EXCEPT
              SELECT
                UNNEST(b)
            )
        '
        LANGUAGE SQL
        IMMUTABLE
        RETURNS NULL ON NULL INPUT;
      """,
      """
      DROP FUNCTION
      array_disjoint(a anyarray, b anyarray);
      """
    )

    alter table(:auto_tracings) do
      remove :unsolved_problems, {:array, Problem.type()}, default: false
    end

    execute(
      """
      ALTER TABLE
        auto_tracings
        ADD unsolved_problems
          #{Problem.type()}[]
          GENERATED ALWAYS AS (ARRAY_DISJOINT(problems, solved_problems))
          STORED
      """,
      """
      ALTER TABLE
        auto_tracings
        DROP unsolved_problems
      """
    )
  end
end
