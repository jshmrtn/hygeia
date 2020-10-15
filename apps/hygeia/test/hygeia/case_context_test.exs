defmodule Hygeia.CaseContextTest do
  @moduledoc false

  use Hygeia.DataCase

  alias Hygeia.CaseContext
  alias Hygeia.CaseContext.Address
  alias Hygeia.CaseContext.Clinical
  alias Hygeia.CaseContext.ContactMethod
  alias Hygeia.CaseContext.Employer
  alias Hygeia.CaseContext.ExternalReference
  alias Hygeia.CaseContext.Hospitalization
  alias Hygeia.CaseContext.Monitoring
  alias Hygeia.CaseContext.Person
  alias Hygeia.CaseContext.Phase
  alias Hygeia.CaseContext.Profession
  alias Hygeia.TenantContext.Tenant
  alias Hygeia.UserContext.User

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
        subdivision: "SG",
        country: "CH"
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
            subdivision: "SG",
            country: "CH"
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
                  subdivision: "SG",
                  country: "CH"
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
                      subdivision: "SG",
                      country: "CH"
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
                  subdivision: "SG",
                  country: "CH"
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
                      subdivision: "SG",
                      country: "CH"
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

  describe "cases" do
    alias Hygeia.CaseContext.Case

    @valid_attrs %{
      complexity: :high,
      status: :first_contact,
      hospitalizations: [
        %{start: ~D[2020-10-13], end: ~D[2020-10-15]},
        %{start: ~D[2020-10-16], end: nil}
      ],
      clinical: %{
        reasons_for_pcr_test: [:symptoms, :outbreak_examination],
        symptoms: [:fever],
        symptom_start: ~D[2020-10-10],
        test: ~D[2020-10-11],
        laboratory_report: ~D[2020-10-12],
        test_kind: :pcr,
        result: :positive
      },
      external_references: [
        %{
          type: :ism,
          value: "7000"
        },
        %{
          type: :other,
          type_name: "foo",
          value: "7000"
        }
      ],
      monitoring: %{
        first_contact: ~D[2020-10-12],
        location: :home,
        location_details: "Bei Mutter zuhause",
        address: %{
          address: "Helmweg 48",
          zip: "8405",
          place: "Winterthur",
          subdivision: "ZH",
          country: "CH"
        }
      },
      phases: [
        %{
          type: :possible_index,
          start: ~D[2020-10-10],
          end: ~D[2020-10-12],
          end_reason: :converted_to_index
        },
        %{
          type: :index,
          start: ~D[2020-10-12],
          end: ~D[2020-10-22],
          end_reason: :healed
        }
      ]
    }
    @update_attrs %{
      complexity: :low,
      status: :done
    }
    @invalid_attrs %{
      complexity: nil,
      status: nil
    }

    test "list_cases/0 returns all cases" do
      case = case_fixture()
      assert CaseContext.list_cases() == [case]
    end

    test "get_case!/1 returns the case with given id" do
      case = case_fixture()
      assert CaseContext.get_case!(case.uuid) == case
    end

    test "create_case/1 with valid data creates a case" do
      tenant = %Tenant{uuid: tenant_uuid} = tenant_fixture()
      person = %Person{uuid: person_uuid} = person_fixture(tenant)
      user = %User{uuid: user_uuid} = user_fixture()

      assert {:ok,
              %Case{
                clinical: %Clinical{
                  laboratory_report: ~D[2020-10-12],
                  reasons_for_pcr_test: [:symptoms, :outbreak_examination],
                  result: :positive,
                  symptom_start: ~D[2020-10-10],
                  symptoms: [:fever],
                  test: ~D[2020-10-11],
                  test_kind: :pcr,
                  uuid: _
                },
                complexity: :high,
                external_references: [
                  %ExternalReference{type: :ism, type_name: nil, uuid: _, value: "7000"},
                  %ExternalReference{type: :other, type_name: "foo", uuid: _, value: "7000"}
                ],
                hospitalizations: [
                  %Hospitalization{end: ~D[2020-10-15], start: ~D[2020-10-13], uuid: _},
                  %Hospitalization{end: nil, start: ~D[2020-10-16], uuid: _}
                ],
                human_readable_id: _,
                inserted_at: _,
                monitoring: %Monitoring{
                  address: %Address{
                    address: "Helmweg 48",
                    country: "CH",
                    place: "Winterthur",
                    subdivision: "ZH",
                    uuid: _,
                    zip: "8405"
                  },
                  first_contact: ~D[2020-10-12],
                  location: :home,
                  location_details: "Bei Mutter zuhause",
                  uuid: _
                },
                phases: [
                  %Phase{
                    end: ~D[2020-10-12],
                    end_reason: :converted_to_index,
                    start: ~D[2020-10-10],
                    type: :possible_index,
                    uuid: _
                  },
                  %Phase{
                    end: ~D[2020-10-22],
                    end_reason: :healed,
                    start: ~D[2020-10-12],
                    type: :index,
                    uuid: _
                  }
                ],
                person: _,
                person_uuid: ^person_uuid,
                status: :first_contact,
                supervisor: _,
                supervisor_uuid: ^user_uuid,
                tenant: _,
                tenant_uuid: ^tenant_uuid,
                tracer: _,
                tracer_uuid: ^user_uuid,
                updated_at: _,
                uuid: _
              }} =
               CaseContext.create_case(
                 person,
                 Map.merge(@valid_attrs, %{tracer_uuid: user.uuid, supervisor_uuid: user.uuid})
               )
    end

    test "create_case/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} =
               CaseContext.create_case(person_fixture(), @invalid_attrs)
    end

    test "update_case/2 with valid data updates the case" do
      case = case_fixture()

      assert {:ok,
              %Case{
                complexity: :low,
                status: :done
              }} = CaseContext.update_case(case, @update_attrs)
    end

    test "update_case/2 with invalid data returns error changeset" do
      case = case_fixture()
      assert {:error, %Ecto.Changeset{}} = CaseContext.update_case(case, @invalid_attrs)
      assert case == CaseContext.get_case!(case.uuid)
    end

    test "delete_case/1 deletes the case" do
      case = case_fixture()
      assert {:ok, %Case{}} = CaseContext.delete_case(case)
      assert_raise Ecto.NoResultsError, fn -> CaseContext.get_case!(case.uuid) end
    end

    test "change_case/1 returns a case changeset" do
      case = case_fixture()
      assert %Ecto.Changeset{} = CaseContext.change_case(case)
    end
  end
end
