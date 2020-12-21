# credo:disable-for-this-file Credo.Check.Readability.Specs
# credo:disable-for-this-file Credo.Check.Design.AliasUsage
defmodule Hygeia.Repo.Migrations.UpdateClinicalSymptomEnum do
  @moduledoc false

  use Hygeia, :migration

  def change do
    Hygeia.CaseContext.Case.Clinical.Symptom.drop_type()
    Hygeia.CaseContext.Case.Clinical.Symptom.create_type()

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
