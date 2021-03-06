defmodule Hygeia.OrganisationContextTest do
  @moduledoc false

  use Hygeia.DataCase

  alias Hygeia.OrganisationContext
  alias Hygeia.OrganisationContext.Affiliation
  alias Hygeia.OrganisationContext.Division
  alias Hygeia.OrganisationContext.Organisation
  alias Hygeia.OrganisationContext.Visit

  @moduletag origin: :test
  @moduletag originator: :noone

  describe "organisations" do
    @valid_attrs %{
      address: %{
        address: "some address",
        zip: "some zip",
        place: "some city",
        subdivision: "SG",
        country: "CH"
      },
      name: "some name",
      notes: "some notes"
    }
    @update_attrs %{
      address: %{
        address: "some updated address",
        zip: "some updated zip",
        place: "some updated city",
        subdivision: "SG",
        country: "CH"
      },
      name: "some updated name",
      notes: "some updated notes"
    }
    @invalid_attrs %{address: %{}, name: nil, notes: nil}

    test "list_organisations/0 returns all organisations" do
      organisation = organisation_fixture()
      assert OrganisationContext.list_organisations() == [organisation]
    end

    test "get_organisation!/1 returns the organisation with given uuid" do
      organisation = organisation_fixture()
      assert OrganisationContext.get_organisation!(organisation.uuid) == organisation
    end

    test "create_organisation/1 with valid data creates a organisation" do
      assert {:ok, %Organisation{} = organisation} =
               OrganisationContext.create_organisation(@valid_attrs)

      assert organisation.address.address == "some address"
      assert organisation.address.zip == "some zip"
      assert organisation.address.place == "some city"
      assert organisation.address.subdivision == "SG"
      assert organisation.address.country == "CH"
      assert organisation.name == "some name"
      assert organisation.notes == "some notes"
    end

    test "create_organisation/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = OrganisationContext.create_organisation(@invalid_attrs)
    end

    test "update_organisation/2 with valid data updates the organisation" do
      organisation = organisation_fixture()

      assert {:ok, %Organisation{} = organisation} =
               OrganisationContext.update_organisation(organisation, @update_attrs)

      assert organisation.address.address == "some updated address"
      assert organisation.address.zip == "some updated zip"
      assert organisation.address.place == "some updated city"
      assert organisation.address.subdivision == "SG"
      assert organisation.address.country == "CH"
      assert organisation.name == "some updated name"
      assert organisation.notes == "some updated notes"
    end

    test "update_organisation/2 with invalid data returns error changeset" do
      organisation = organisation_fixture()

      assert {:error, %Ecto.Changeset{}} =
               OrganisationContext.update_organisation(organisation, @invalid_attrs)

      assert organisation == OrganisationContext.get_organisation!(organisation.uuid)
    end

    test "delete_organisation/1 deletes the organisation" do
      organisation = organisation_fixture()
      assert {:ok, %Organisation{}} = OrganisationContext.delete_organisation(organisation)

      assert_raise Ecto.NoResultsError, fn ->
        OrganisationContext.get_organisation!(organisation.uuid)
      end
    end

    test "change_organisation/1 returns a organisation changeset" do
      organisation = organisation_fixture()
      assert %Ecto.Changeset{} = OrganisationContext.change_organisation(organisation)
    end

    test "merge_organisation/2 moves all data to target and deletes source" do
      organisation_1 = organisation_fixture(%{name: "JOSHMARTIN GmbH"})
      _affiliation_1a = affiliation_fixture(person_fixture(), organisation_1, %{kind: :employee})
      division_1 = division_fixture(organisation_1, %{title: "Division 1"})

      _affiliation_1b =
        affiliation_fixture(person_fixture(), organisation_1, %{
          kind: :employee,
          division_uuid: division_1.uuid
        })

      organisation_2 = organisation_fixture(%{name: "JOHSMARTIN GmbH"})
      _affiliation_2a = affiliation_fixture(person_fixture(), organisation_2, %{kind: :scholar})
      division_2 = division_fixture(organisation_2, %{title: "Division 2"})

      _affiliation_2b =
        affiliation_fixture(person_fixture(), organisation_2, %{
          kind: :employee,
          division_uuid: division_2.uuid
        })

      assert {:ok, organisation_into} =
               OrganisationContext.merge_organisations(organisation_2, organisation_1)

      assert %Organisation{affiliations: [_, _, _, _], divisions: [_, _]} =
               Repo.preload(organisation_into, affiliations: [], divisions: [])

      assert_raise Ecto.NoResultsError, fn ->
        OrganisationContext.get_organisation!(organisation_2.uuid)
      end
    end
  end

  describe "affiliations" do
    @valid_attrs %{kind: :employee, kind_other: nil}
    @update_attrs %{kind: :other, kind_other: "some updated kind_other"}
    @invalid_attrs %{kind: :other, kind_other: nil}

    test "list_affiliations/0 returns all affiliations" do
      affiliation = affiliation_fixture()
      assert OrganisationContext.list_affiliations() == [affiliation]
    end

    test "get_affiliation!/1 returns the affiliation with given id" do
      affiliation = affiliation_fixture()
      assert OrganisationContext.get_affiliation!(affiliation.uuid) == affiliation
    end

    test "create_affiliation/1 with valid data creates a affiliation" do
      assert {:ok, %Affiliation{} = affiliation} =
               OrganisationContext.create_affiliation(
                 person_fixture(),
                 organisation_fixture(),
                 @valid_attrs
               )

      assert affiliation.kind == :employee
      assert affiliation.kind_other == nil
    end

    test "create_affiliation/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} =
               OrganisationContext.create_affiliation(
                 person_fixture(),
                 organisation_fixture(),
                 @invalid_attrs
               )
    end

    test "update_affiliation/2 with valid data updates the affiliation" do
      affiliation = affiliation_fixture()

      assert {:ok, %Affiliation{} = affiliation} =
               OrganisationContext.update_affiliation(affiliation, @update_attrs)

      assert affiliation.kind == :other
      assert affiliation.kind_other == "some updated kind_other"
    end

    test "update_affiliation/2 with invalid data returns error changeset" do
      affiliation = affiliation_fixture()

      assert {:error, %Ecto.Changeset{}} =
               OrganisationContext.update_affiliation(affiliation, @invalid_attrs)

      assert affiliation == OrganisationContext.get_affiliation!(affiliation.uuid)
    end

    test "delete_affiliation/1 deletes the affiliation" do
      affiliation = affiliation_fixture()
      assert {:ok, %Affiliation{}} = OrganisationContext.delete_affiliation(affiliation)

      assert_raise Ecto.NoResultsError, fn ->
        OrganisationContext.get_affiliation!(affiliation.uuid)
      end
    end

    test "change_affiliation/1 returns a affiliation changeset" do
      affiliation = affiliation_fixture()
      assert %Ecto.Changeset{} = OrganisationContext.change_affiliation(affiliation)
    end
  end

  describe "divisions" do
    @valid_attrs %{description: "some description", title: "some title"}
    @update_attrs %{description: "some updated description", title: "some updated title"}
    @invalid_attrs %{description: nil, title: nil}

    test "list_divisions/0 returns all divisions" do
      division = division_fixture()
      assert OrganisationContext.list_divisions() == [division]
    end

    test "get_division!/1 returns the division with given id" do
      division = division_fixture()
      assert OrganisationContext.get_division!(division.uuid) == division
    end

    test "create_division/1 with valid data creates a division" do
      assert {:ok, %Division{} = division} =
               OrganisationContext.create_division(organisation_fixture(), @valid_attrs)

      assert division.description == "some description"
      assert division.title == "some title"
    end

    test "create_division/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} =
               OrganisationContext.create_division(organisation_fixture(), @invalid_attrs)
    end

    test "update_division/2 with valid data updates the division" do
      division = division_fixture()

      assert {:ok, %Division{} = division} =
               OrganisationContext.update_division(division, @update_attrs)

      assert division.description == "some updated description"
      assert division.title == "some updated title"
    end

    test "update_division/2 with invalid data returns error changeset" do
      division = division_fixture()

      assert {:error, %Ecto.Changeset{}} =
               OrganisationContext.update_division(division, @invalid_attrs)

      assert division == OrganisationContext.get_division!(division.uuid)
    end

    test "delete_division/1 deletes the division" do
      division = division_fixture()
      assert {:ok, %Division{}} = OrganisationContext.delete_division(division)
      assert_raise Ecto.NoResultsError, fn -> OrganisationContext.get_division!(division.uuid) end
    end

    test "change_division/1 returns a division changeset" do
      division = division_fixture()
      assert %Ecto.Changeset{} = OrganisationContext.change_division(division)
    end

    test "merge_divisions/2 moves all data to target and deletes source" do
      organisation = organisation_fixture(%{name: "JOSHMARTIN GmbH"})
      division_1 = division_fixture(organisation, %{title: "Division 1"})

      _affiliation_1 =
        affiliation_fixture(person_fixture(), organisation, %{
          kind: :employee,
          division_uuid: division_1.uuid
        })

      division_2 = division_fixture(organisation, %{title: "Division 2"})

      _affiliation_2 =
        affiliation_fixture(person_fixture(), organisation, %{
          kind: :employee,
          division_uuid: division_2.uuid
        })

      assert {:ok, division_into} = OrganisationContext.merge_divisions(division_2, division_1)

      assert %Division{affiliations: [_, _]} = Repo.preload(division_into, affiliations: [])

      assert_raise Ecto.NoResultsError, fn ->
        OrganisationContext.get_division!(division_2.uuid)
      end
    end
  end

  describe "visits" do
    @invalid_attrs %{
      reason: :wrong
    }

    test "list_visits/0 returns all visits" do
      visit = visit_fixture(case_fixture(), %{reason: :student})
      assert OrganisationContext.list_visits() == [visit]
    end

    test "get_visit!/1 returns the visit with given id" do
      visit = visit_fixture(case_fixture(), %{reason: :student})
      assert OrganisationContext.get_visit!(visit.uuid) == visit
    end

    test "create_visit/1 with valid data creates a visit" do
      valid_attrs = %{
        reason: :visitor,
        last_visit_at: Date.add(Date.utc_today(), -5),
        unknown_organisation: %{
          address: %{
            address: "Torstrasse 25",
            zip: "9000",
            place: "St. Gallen",
            subdivision: "SG",
            country: "CH"
          }
        }
      }

      assert {:ok, %Visit{}} = OrganisationContext.create_visit(case_fixture(), valid_attrs)
    end

    test "create_visit/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} =
               OrganisationContext.create_visit(case_fixture(), @invalid_attrs)
    end

    test "update_visit/2 with valid data updates the visit" do
      visit = visit_fixture(case_fixture(), %{reason: :student})
      update_attrs = %{reason: :visitor}

      assert {:ok, %Visit{}} = OrganisationContext.update_visit(visit, update_attrs)
    end

    test "update_visit/2 with invalid data returns error changeset" do
      visit = visit_fixture(case_fixture(), %{reason: :student})
      assert {:error, %Ecto.Changeset{}} = OrganisationContext.update_visit(visit, @invalid_attrs)
      assert visit == OrganisationContext.get_visit!(visit.uuid)
    end

    test "delete_visit/1 deletes the visit" do
      visit = visit_fixture(case_fixture(), %{reason: :student})
      assert {:ok, %Visit{}} = OrganisationContext.delete_visit(visit)
      assert_raise Ecto.NoResultsError, fn -> OrganisationContext.get_visit!(visit.uuid) end
    end

    test "change_visit/1 returns a visit changeset" do
      visit = visit_fixture(case_fixture(), %{reason: :student})
      assert %Ecto.Changeset{} = OrganisationContext.change_visit(visit)
    end
  end
end
