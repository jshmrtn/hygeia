defmodule Hygeia.CaseContextTest do
  @moduledoc false

  use Hygeia.DataCase

  alias Hygeia.CaseContext
  alias Hygeia.CaseContext.Address
  alias Hygeia.CaseContext.ContactMethod
  alias Hygeia.CaseContext.Employer
  alias Hygeia.CaseContext.Person
  alias Hygeia.CaseContext.Profession

  @moduletag origin: :test
  @moduletag originator: :noone

  describe "professions" do
    @valid_attrs %{name: "some name"}
    @update_attrs %{name: "some updated name"}
    @invalid_attrs %{name: nil}

    test "list_professions/0 returns all professions" do
      profession = profession_fixture()
      assert CaseContext.list_professions() == [profession]
    end

    test "get_profession!/1 returns the profession with given id" do
      profession = profession_fixture()
      assert CaseContext.get_profession!(profession.uuid) == profession
    end

    test "create_profession/1 with valid data creates a profession" do
      assert {:ok, %Profession{} = profession} = CaseContext.create_profession(@valid_attrs)
      assert profession.name == "some name"
    end

    test "create_profession/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = CaseContext.create_profession(@invalid_attrs)
    end

    test "update_profession/2 with valid data updates the profession" do
      profession = profession_fixture()

      assert {:ok, %Profession{} = profession} =
               CaseContext.update_profession(profession, @update_attrs)

      assert profession.name == "some updated name"
    end

    test "update_profession/2 with invalid data returns error changeset" do
      profession = profession_fixture()

      assert {:error, %Ecto.Changeset{}} =
               CaseContext.update_profession(profession, @invalid_attrs)

      assert profession == CaseContext.get_profession!(profession.uuid)
    end

    test "delete_profession/1 deletes the profession" do
      profession = profession_fixture()
      assert {:ok, %Profession{}} = CaseContext.delete_profession(profession)
      assert_raise Ecto.NoResultsError, fn -> CaseContext.get_profession!(profession.uuid) end
    end

    test "change_profession/1 returns a profession changeset" do
      profession = profession_fixture()
      assert %Ecto.Changeset{} = CaseContext.change_profession(profession)
    end
  end

  describe "people" do
    alias Hygeia.CaseContext.Person

    @valid_attrs %{
      address: %{
        address: "Neugasse 51",
        zip: "9000",
        place: "St. Gallen",
        region: "St. Gallen",
        country: "CHE"
      },
      birth_date: ~D[2010-04-17],
      contact_methods: [
        %{
          type: :mobile,
          value: "+41 78 724 57 90",
          comment: "Call only between 7 and 9 am"
        }
      ],
      employers: [
        %{
          name: "JOSHMARTIN GmbH",
          address: %{
            address: "Neugasse 51",
            zip: "9000",
            place: "St. Gallen",
            region: "St. Gallen",
            country: "CHE"
          }
        }
      ],
      external_references: [],
      first_name: "some first_name",
      last_name: "some last_name",
      sex: :female
    }
    @update_attrs %{
      birth_date: ~D[2011-05-18],
      first_name: "some updated first_name",
      last_name: "some updated last_name",
      sex: :male
    }
    @invalid_attrs %{
      address: nil,
      birth_date: nil,
      contact_methods: nil,
      employers: nil,
      external_references: nil,
      first_name: nil,
      last_name: nil,
      sex: nil
    }

    test "list_people/0 returns all people" do
      person = person_fixture()
      assert CaseContext.list_people() == [person]
    end

    test "get_person!/1 returns the person with given id" do
      person = person_fixture()
      assert CaseContext.get_person!(person.uuid) == person
    end

    test "create_person/1 with valid data creates a person" do
      tenant = tenant_fixture()

      assert {:ok,
              %Person{
                address: %Address{
                  address: "Neugasse 51",
                  zip: "9000",
                  place: "St. Gallen",
                  region: "St. Gallen",
                  country: "CHE"
                },
                birth_date: ~D[2010-04-17],
                contact_methods: [
                  %ContactMethod{
                    type: :mobile,
                    value: "+41 78 724 57 90",
                    comment: "Call only between 7 and 9 am"
                  }
                ],
                employers: [
                  %Employer{
                    name: "JOSHMARTIN GmbH",
                    address: %Address{
                      address: "Neugasse 51",
                      zip: "9000",
                      place: "St. Gallen",
                      region: "St. Gallen",
                      country: "CHE"
                    }
                  }
                ],
                external_references: [],
                first_name: "some first_name",
                human_readable_id: _,
                last_name: "some last_name",
                sex: :female
              }} = CaseContext.create_person(tenant, @valid_attrs)
    end

    test "create_person/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} =
               CaseContext.create_person(tenant_fixture(), @invalid_attrs)
    end

    test "update_person/2 with valid data updates the person" do
      person = person_fixture()

      assert {:ok,
              %Person{
                address: %Address{
                  address: "Neugasse 51",
                  zip: "9000",
                  place: "St. Gallen",
                  region: "St. Gallen",
                  country: "CHE"
                },
                birth_date: ~D[2011-05-18],
                contact_methods: [
                  %ContactMethod{
                    type: :mobile,
                    value: "+41 78 724 57 90",
                    comment: "Call only between 7 and 9 am"
                  }
                ],
                employers: [
                  %Employer{
                    name: "JOSHMARTIN GmbH",
                    address: %Address{
                      address: "Neugasse 51",
                      zip: "9000",
                      place: "St. Gallen",
                      region: "St. Gallen",
                      country: "CHE"
                    }
                  }
                ],
                external_references: [
                  %Hygeia.CaseContext.ExternalReference{
                    type: :ism,
                    type_name: nil,
                    uuid: _,
                    value: "7000"
                  },
                  %Hygeia.CaseContext.ExternalReference{
                    type: :other,
                    type_name: "foo",
                    uuid: _,
                    value: "7000"
                  }
                ],
                first_name: "some updated first_name",
                human_readable_id: _,
                last_name: "some updated last_name",
                sex: :male
              }} = CaseContext.update_person(person, @update_attrs)
    end

    test "update_person/2 with invalid data returns error changeset" do
      person = person_fixture()
      assert {:error, %Ecto.Changeset{}} = CaseContext.update_person(person, @invalid_attrs)
      assert person == CaseContext.get_person!(person.uuid)
    end

    test "delete_person/1 deletes the person" do
      person = person_fixture()
      assert {:ok, %Person{}} = CaseContext.delete_person(person)
      assert_raise Ecto.NoResultsError, fn -> CaseContext.get_person!(person.uuid) end
    end

    test "change_person/1 returns a person changeset" do
      person = person_fixture()
      assert %Ecto.Changeset{} = CaseContext.change_person(person)
    end
  end
end
