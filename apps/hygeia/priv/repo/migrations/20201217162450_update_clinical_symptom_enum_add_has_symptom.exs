# credo:disable-for-this-file Credo.Check.Readability.Specs
defmodule Hygeia.Repo.Migrations.UpdateClinicalSymptomEnumAddHasSymptom do
  @moduledoc false

  use Hygeia, :migration

  @disable_ddl_transaction true

  def up do
    execute("""
    ALTER TYPE symptom ADD VALUE IF NOT EXISTS 'muscle_pain' BEFORE 'other';
    """)

    execute("""
    ALTER TYPE symptom ADD VALUE IF NOT EXISTS 'general_weakness' BEFORE 'other';
    """)

    execute("""
    ALTER TYPE symptom ADD VALUE IF NOT EXISTS 'gastrointestinal' BEFORE 'other';
    """)

    execute("""
    ALTER TYPE symptom ADD VALUE IF NOT EXISTS 'skin_rash' BEFORE 'other';
    """)

    execute("""
    UPDATE cases
    SET clinical = 
      clinical || jsonb_build_object('has_symptoms', 
        CASE
          WHEN clinical->>'symptoms' IS NOT NULL AND char_length(clinical->>'symptoms') > 2 THEN true
          ELSE NULL
        END)
    """)
  end
end
