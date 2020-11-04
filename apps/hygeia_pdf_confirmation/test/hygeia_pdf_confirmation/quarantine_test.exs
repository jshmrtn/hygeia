defmodule HygeiaPdfConfirmation.QuarantineTest do
  @moduledoc false

  use HygeiaPdfConfirmation.Case
  use Hygeia.DataCase

  alias HygeiaPdfConfirmation.Quarantine

  @moduletag origin: :test
  @moduletag originator: :noone

  describe "render_pdf/2" do
    test "generates pdf" do
      person = person_fixture()
      %{phases: [phase | _]} = case = case_fixture(person)

      assert pdf_binary = Quarantine.render_pdf(case, phase)

      assert text_string = pdf_string(pdf_binary)

      assert text_string =~ "Quarantine"
      assert text_string =~ person.first_name
      assert text_string =~ person.last_name
    end
  end
end
