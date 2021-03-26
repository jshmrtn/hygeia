defmodule HygeiaPdfConfirmation.IsolationTest do
  @moduledoc false

  use HygeiaPdfConfirmation.Case
  use Hygeia.DataCase

  alias HygeiaPdfConfirmation.Isolation

  @moduletag origin: :test
  @moduletag originator: :noone

  describe "render_pdf/2" do
    test "generates pdf" do
      for variation <- HygeiaPdfConfirmation.template_variations() do
        tenant = tenant_fixture(%{template_variation: variation})
        person = person_fixture(tenant)
        %{phases: [phase | _]} = case = case_fixture(person)

        assert pdf_binary = Isolation.render_pdf(case, phase)

        assert text_string = pdf_string(pdf_binary)

        text_string = String.replace(text_string, "\n", " ")

        assert text_string =~ "Isolation"
        assert text_string =~ person.first_name
        assert text_string =~ person.last_name
      end
    end
  end
end
