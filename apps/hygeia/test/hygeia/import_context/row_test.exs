defmodule Hygeia.ImportContext.RowTest do
  @moduledoc false

  use Hygeia.DataCase

  alias Hygeia.ImportContext.Row

  @moduletag origin: :test
  @moduletag originator: :noone

  describe "get_changes/2" do
    for {{predecessor_data, predecessor_corrected, data, corrected, result}, index} <-
          Enum.with_index([
            {%{"Name" => "JONATAN"}, %{}, %{"Name" => "JONATAN"}, %{}, %{}},
            {%{"Name" => "JONY"}, %{"Name" => "Jony"}, %{"Name" => "JONATAN"},
             %{"Name" => "Jonatan"}, %{"Name" => "Jonatan"}},
            {%{"Name" => "JONY"}, %{"Name" => "Jony"}, %{"Name" => "Jonatan"}, %{},
             %{"Name" => "Jonatan"}},
            {%{"Name" => "JONATAN"}, %{"Name" => "Jonatan"}, %{"Name" => "JONATAN"}, %{}, %{}},
            {%{"Name" => "JONATAN"}, %{"Name" => "Jonatan"}, %{"Name" => "JONY"}, %{},
             %{"Name" => "JONY"}},
            {%{"Name" => "JONATAN"}, %{}, %{"Name" => "JONY"}, %{}, %{"Name" => "JONY"}},
            {%{"Name" => "Jonatan"}, %{}, %{}, %{}, %{"Name" => nil}}
          ]) do
      @data data
      @corrected corrected
      @predecessor_data predecessor_data
      @predecessor_corrected predecessor_corrected
      @result result
      test "finds correct diff ##{index}" do
        assert @result ==
                 Row.get_changes(%Row{data: @data, corrected: @corrected}, %Row{
                   data: @predecessor_data,
                   corrected: @predecessor_corrected
                 })
      end
    end

    test "works with empty" do
      assert %{"Vorname" => "Jonatan", "Nachname" => "Männchen"} ==
               Row.get_changes(
                 %Row{
                   data: %{"Vorname" => "JONATAN", "Nachname" => "Männchen"},
                   corrected: %{"Vorname" => "Jonatan"}
                 },
                 nil
               )
    end
  end
end
