defmodule Hygeia.OrganisationContextTest do
  @moduledoc false

  use Hygeia.DataCase

  alias Hygeia.OrganisationContext
  alias Hygeia.OrganisationContext.Organisation

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
  end

  describe "positions" do
    alias Hygeia.OrganisationContext.Position

    @valid_attrs %{position: "some position"}
    @update_attrs %{position: "some updated position"}
    @invalid_attrs %{position: nil}

    test "list_positions/0 returns all positions" do
      position = position_fixture()
      assert OrganisationContext.list_positions() == [position]
    end

    test "get_position!/1 returns the position with given id" do
      position = position_fixture()
      assert OrganisationContext.get_position!(position.uuid) == position
    end

    test "create_position/1 with valid data creates a position" do
      organisation = organisation_fixture()
      person = person_fixture()

      attrs =
        Enum.into(%{person_uuid: person.uuid, organisation_uuid: organisation.uuid}, @valid_attrs)

      assert {:ok, %Position{} = position} = OrganisationContext.create_position(attrs)
      assert position.position == "some position"
    end

    test "create_position/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = OrganisationContext.create_position(@invalid_attrs)
    end

    test "update_position/2 with valid data updates the position" do
      position = position_fixture()

      assert {:ok, %Position{} = position} =
               OrganisationContext.update_position(position, @update_attrs)

      assert position.position == "some updated position"
    end

    test "update_position/2 with invalid data returns error changeset" do
      position = position_fixture()

      assert {:error, %Ecto.Changeset{}} =
               OrganisationContext.update_position(position, @invalid_attrs)

      assert position == OrganisationContext.get_position!(position.uuid)
    end

    test "delete_position/1 deletes the position" do
      position = position_fixture()
      assert {:ok, %Position{}} = OrganisationContext.delete_position(position)
      assert_raise Ecto.NoResultsError, fn -> OrganisationContext.get_position!(position.uuid) end
    end

    test "change_position/1 returns a position changeset" do
      position = position_fixture()
      assert %Ecto.Changeset{} = OrganisationContext.change_position(position)
    end
  end
end
