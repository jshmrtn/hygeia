defmodule HygeiaWeb.AffiliationLiveTest do
  @moduledoc false

  use Hygeia.DataCase
  use HygeiaWeb.ConnCase

  import Phoenix.LiveViewTest

  @moduletag origin: :test
  @moduletag originator: :noone
  @moduletag log_in: [roles: [:admin]]

  defp create_organisation(_tags) do
    %{organisation: organisation_fixture()}
  end

  defp create_person(_tags) do
    %{person: person_fixture()}
  end

  defp create_affiliation(%{person: person, organisation: organisation}) do
    %{affiliation: affiliation_fixture(person, organisation, %{comment: "some comment"})}
  end

  describe "Index" do
    setup [:create_organisation, :create_person, :create_affiliation]

    test "lists all affiliations", %{
      conn: conn,
      organisation: organisation,
      person: person,
      affiliation: affiliation
    } do
      {:ok, _index_live, html} =
        live(conn, Routes.affiliation_index_path(conn, :index, organisation))

      assert html =~ organisation.name
      assert html =~ person.first_name
      assert html =~ affiliation.comment
    end
  end
end
