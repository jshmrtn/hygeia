defmodule Hygeia.CaseContextTest do
  @moduledoc false

  use Hygeia.DataCase

  alias Hygeia.CaseContext
  alias Hygeia.CaseContext.Address
  alias Hygeia.CaseContext.Case
  alias Hygeia.CaseContext.Case.Clinical
  alias Hygeia.CaseContext.Case.Hospitalization
  alias Hygeia.CaseContext.Case.Monitoring
  alias Hygeia.CaseContext.Case.Phase
  alias Hygeia.CaseContext.Employer
  alias Hygeia.CaseContext.ExternalReference
  alias Hygeia.CaseContext.Person
  alias Hygeia.CaseContext.Person.ContactMethod
  alias Hygeia.CaseContext.PossibleIndexSubmission
  alias Hygeia.CaseContext.Transmission
  alias Hygeia.OrganisationContext.Organisation
  alias Hygeia.TenantContext.Tenant
  alias Hygeia.UserContext.User

  @moduletag origin: :test
  @moduletag originator: :noone

  describe "people" do
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

    test "create_person/1 with valid data formats phone number" do
      tenant = tenant_fixture()

      assert {:ok,
              %Person{
                contact_methods: [
                  %ContactMethod{
                    type: :mobile,
                    value: "+41 78 724 57 90"
                  },
                  %ContactMethod{
                    type: :mobile,
                    value: "+41 78 724 57 90"
                  },
                  %ContactMethod{
                    type: :landline,
                    value: "+41 71 511 72 54"
                  },
                  %ContactMethod{
                    type: :email,
                    value: "example@example.com"
                  }
                ]
              }} =
               CaseContext.create_person(tenant, %{
                 contact_methods: [
                   %{
                     type: :mobile,
                     value: "+41 78 724 57 90"
                   },
                   %{
                     type: :mobile,
                     value: "078 724 57 90"
                   },
                   %{
                     type: :landline,
                     value: "0041715117254"
                   },
                   %{
                     type: :email,
                     value: "example@example.com"
                   }
                 ],
                 first_name: "some first_name",
                 last_name: "some last_name"
               })
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
                    type: :ism_case,
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

    test "person_has_mobile_number?/1 returns true if exists" do
      tenant = tenant_fixture()

      person =
        person_fixture(tenant, %{contact_methods: [%{type: :mobile, value: "+41787245790"}]})

      assert CaseContext.person_has_mobile_number?(person)
    end

    test "person_has_mobile_number?/1 returns false if not exists" do
      tenant = tenant_fixture()

      person = person_fixture(tenant, %{contact_methods: []})

      refute CaseContext.person_has_mobile_number?(person)
    end

    test "list_people_by_contact_method/2 finds relevant people" do
      tenant = tenant_fixture()

      person_matching =
        person_fixture(tenant, %{contact_methods: [%{type: :mobile, value: "+41 87 812 34 56"}]})

      _person_not_matching_value =
        person_fixture(tenant, %{contact_methods: [%{type: :mobile, value: "+41 87 812 34 58"}]})

      _person_not_matching_type =
        person_fixture(tenant, %{contact_methods: [%{type: :landline, value: "+41 878 123 456"}]})

      assert [^person_matching] =
               CaseContext.list_people_by_contact_method(:mobile, "+41878123456")
    end

    test "list_people_by_name/2 finds relevant people" do
      tenant = tenant_fixture()

      _person_matching = person_fixture(tenant, %{first_name: "Max", last_name: "Muster"})
      _person_little_matching = person_fixture(tenant, %{first_name: "Maxi", last_name: "Muster"})

      _person_not_matching = person_fixture(tenant, %{first_name: "Peter", last_name: "Muster"})

      assert [
               %Person{first_name: "Max", last_name: "Muster"},
               %Person{first_name: "Maxi", last_name: "Muster"}
             ] = CaseContext.list_people_by_name("Max", "Muster")
    end
  end

  describe "cases" do
    @valid_attrs %{
      complexity: :high,
      status: :first_contact,
      hospitalizations: [
        %{start: ~D[2020-10-13], end: ~D[2020-10-15]},
        %{start: ~D[2020-10-16], end: nil}
      ],
      clinical: %{
        reasons_for_test: [:symptoms, :outbreak_examination],
        has_symptoms: true,
        symptoms: [:fever],
        test: ~D[2020-10-11],
        laboratory_report: ~D[2020-10-12],
        test_kind: :pcr,
        result: :positive,
        symptom_start: ~D[2020-10-10]
      },
      external_references: [
        %{
          type: :ism_case,
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
          details: %{
            __type__: :possible_index,
            type: :contact_person,
            end_reason: :converted_to_index
          },
          start: ~D[2020-10-10],
          end: ~D[2020-10-12]
        },
        %{
          details: %{
            __type__: :index,
            end_reason: :healed
          },
          start: ~D[2020-10-12],
          end: ~D[2020-10-22]
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
      organisation = organisation_fixture()

      assert {:ok,
              %Case{
                clinical: %Clinical{
                  laboratory_report: ~D[2020-10-12],
                  reasons_for_test: [:symptoms, :outbreak_examination],
                  result: :positive,
                  has_symptoms: true,
                  symptoms: [:fever],
                  test: ~D[2020-10-11],
                  test_kind: :pcr,
                  uuid: _,
                  symptom_start: ~D[2020-10-10]
                },
                complexity: :high,
                external_references: [
                  %ExternalReference{type: :ism_case, type_name: nil, uuid: _, value: "7000"},
                  %ExternalReference{type: :other, type_name: "foo", uuid: _, value: "7000"}
                ],
                hospitalizations: [
                  %Hospitalization{end: ~D[2020-10-15], start: ~D[2020-10-13], uuid: _} =
                    hospitalization,
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
                    details: %Phase.PossibleIndex{
                      type: :contact_person,
                      end_reason: :converted_to_index
                    },
                    end: ~D[2020-10-12],
                    start: ~D[2020-10-10],
                    uuid: _
                  },
                  %Phase{
                    details: %Phase.Index{
                      end_reason: :healed
                    },
                    end: ~D[2020-10-22],
                    start: ~D[2020-10-12],
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
                 @valid_attrs
                 |> Map.merge(%{tracer_uuid: user.uuid, supervisor_uuid: user.uuid})
                 |> put_in(
                   [:hospitalizations, Access.at(0), :organisation_uuid],
                   organisation.uuid
                 )
               )

      assert %Hospitalization{organisation: %Organisation{}} =
               Repo.preload(hospitalization, :organisation)
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

    test "relate_case_to_organisation/2 relates organisation" do
      case = case_fixture()
      organisation = organisation_fixture()

      {:ok, %Case{related_organisations: [^organisation]}} =
        CaseContext.relate_case_to_organisation(case, organisation)
    end

    test "case_export/1 exports :bag_med_16122020_case" do
      Repo.transaction(fn ->
        user = user_fixture()
        tenant = tenant_fixture()

        person_jony =
          person_fixture(tenant, %{
            first_name: "Jonatan",
            last_name: "Männchen",
            sex: :male,
            birth_date: ~D[1993-01-30],
            address: %{
              address: "Erlen 4",
              zip: "9042",
              place: "Speicher",
              subdivision: "AR",
              country: "CH"
            },
            contact_methods: [
              %{type: :mobile, value: "+41787245790"},
              %{type: :landline, value: "+41522330689"}
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
            vaccination: %{
              done: true,
              name: "Biontech",
              jab_dates: [~D[2021-01-01], ~D[2021-02-03]]
            },
            profession_category: :"74",
            profession_category_main: :M
          })

        person_jay =
          person_fixture(tenant, %{
            address: %{
              address: "Hebelstrasse 20",
              zip: "9000",
              place: "St. Gallen",
              subdivision: "SG",
              country: "CH"
            },
            birth_date: ~D[1992-03-27],
            contact_methods: [
              %{
                type: :mobile,
                value: "+41 79 794 57 83"
              }
            ],
            external_references: [
              %{
                type: :ism_case,
                value: "7002"
              }
            ],
            first_name: "Jeremy",
            last_name: "Zahner",
            profession_category: :"74",
            profession_category_main: :M,
            sex: :male
          })

        case_jony =
          case_fixture(person_jony, user, user, %{
            uuid: "ca98a59b-64c5-4476-9abd-d91d2d1d24e3",
            external_references: [
              %{type: :ism_case, value: "ISM ID"}
            ],
            monitoring: %{
              location: :home,
              location_details: "Bei Mutter zuhause"
            },
            phases: [
              %{
                details: %{
                  __type__: :possible_index,
                  type: :travel
                },
                start: ~D[2020-10-03],
                end: ~D[2020-10-06]
              },
              %{
                details: %{
                  __type__: :index,
                  type: :contact_person,
                  end_reason: :healed
                },
                start: ~D[2020-10-06],
                end: ~D[2020-10-16]
              }
            ],
            clinical: %{
              has_symptoms: true,
              symptoms: [:fever],
              reasons_for_test: [:symptoms],
              test_kind: :serology,
              result: :positive,
              symptom_start: ~D[2020-10-04]
            }
          })

        _note_case_jony = sms_fixture(case_jony, %{inserted_at: ~U[2021-01-05 11:55:10.783294Z]})

        case_jay =
          case_fixture(person_jay, user, user, %{
            uuid: "dd1911a3-a79f-4594-8439-5b0455569e9e",
            monitoring: %{
              location: :home
            },
            phases: [
              %{
                details: %{
                  __type__: :possible_index,
                  type: :contact_person
                },
                start: ~D[2020-10-06],
                end: ~D[2020-10-10]
              },
              %{
                details: %{
                  __type__: :index,
                  type: :contact_person
                },
                start: ~D[2020-10-10],
                end: ~D[2020-10-20]
              }
            ],
            clinical: %{
              has_symptoms: false,
              reasons_for_test: [:contact_tracing]
            }
          })

        transmission_jony =
          transmission_fixture(%{
            date: Date.add(Date.utc_today(), -5),
            propagator_internal: nil,
            recipient_internal: true,
            recipient_case_uuid: case_jony.uuid,
            infection_place: %{
              address: %{
                country: "GB"
              },
              known: true,
              activity_mapping_executed: true,
              activity_mapping: "Seat 3A",
              type: :flight,
              name: "Swiss International Airlines",
              flight_information: "LX332"
            }
          })

        transmission_jony_jay =
          transmission_fixture(%{
            date: Date.add(Date.utc_today(), -2),
            propagator_internal: true,
            propagator_case_uuid: case_jony.uuid,
            recipient_internal: true,
            recipient_case_uuid: case_jay.uuid,
            infection_place: %{
              address: %{
                address: "Torstrasse 25",
                zip: "9000",
                place: "St. Gallen",
                subdivision: "SG",
                country: "CH"
              },
              known: true,
              activity_mapping_executed: true,
              activity_mapping: "Drank beer, kept distance to other people",
              type: :flight,
              name: "BrüW",
              flight_information: nil
            }
          })

        transmission_jony_date = Date.to_iso8601(transmission_jony.date)
        transmission_jony_jay_date = Date.to_iso8601(transmission_jony_jay.date)

        assert [
                 %{
                   "exp_loc_type_high_school" => "0",
                   "exp_loc_name" => "Swiss International Airlines",
                   "test_type" => "5",
                   "work_place_street_number" => "",
                   "exp_loc_type_choir" => "0",
                   "work_place_location" => "St. Gallen",
                   "first_name" => "Jonatan",
                   "iso_loc_street_number" => "",
                   "test_reason_quarantine" => "0",
                   "end_of_iso_dt" => "2020-10-16",
                   "case_link_ktn_internal_id" => "",
                   "test_reason_app" => "0",
                   "lab_report_dt" => "",
                   "exp_loc_type_cinema" => "0",
                   "date_of_birth" => "1993-01-30",
                   "exp_loc_type_asyl" => "0",
                   "test_result" => "1",
                   "symptom_onset_dt" => "2020-10-04",
                   "work_place_postal_code" => "9000",
                   "vacc_name" => "Biontech",
                   "exp_loc_type_medical" => "0",
                   "vacc_dose" => "2",
                   "exp_loc_type_indoor_sport" => "0",
                   "last_name" => "Männchen",
                   "exp_loc_type_army" => "0",
                   "exp_loc_type_shop" => "0",
                   "exp_loc_dt" => ^transmission_jony_date,
                   "iso_loc_type" => "1",
                   "country" => "8100",
                   "test_reason_work_screening" => "0",
                   "exp_type" => "2",
                   "test_reason_convenience" => "0",
                   "reason_end_of_iso" => "",
                   "work_place_name" => "JOSHMARTIN GmbH",
                   "exp_loc_type_yn" => "1",
                   "test_reason_cohort" => "0",
                   "exp_loc_type_work_place" => "0",
                   "exp_loc_type_school_camp" => "0",
                   "work_place_street" => "Neugasse 51",
                   "exp_loc_type_gathering" => "0",
                   "profession" => "M",
                   "reason_quar" => "2",
                   "vacc_dt_first" => "2021-01-01",
                   "exp_loc_flightdetail" => "LX332",
                   "exp_loc_postal_code" => "",
                   "vacc_yn" => "1",
                   "corr_ct_dt" => "",
                   "mobile_number" => "+41787245790",
                   "street_name" => "Erlen 4",
                   "case_link_contact_dt" => ^transmission_jony_date,
                   "exp_loc_type_club" => "0",
                   "onset_iso_dt" => "2020-10-06",
                   "test_reason_symptoms" => "1",
                   "exp_loc_street" => "",
                   "ktn_internal_id" => "ca98a59b-64c5-4476-9abd-d91d2d1d24e3",
                   "work_place_country" => "8100",
                   "other_exp_loc_type_yn" => "0",
                   "phone_number" => "+41522330689",
                   "exp_loc_type_nursing_home" => "0",
                   "exp_loc_type_public_transp" => "0",
                   "exp_loc_type_more_300" => "0",
                   "exp_loc_type_child_home" => "0",
                   "quar_yn" => "1",
                   "exp_loc_type_religion" => "0",
                   "activity_mapping_yn" => "",
                   "exp_loc_type_restaurant" => "0",
                   "location" => "Speicher",
                   "symptoms_yn" => "1",
                   "exp_loc_type_hotel" => "0",
                   "exp_loc_type_childcare" => "0",
                   "test_reason_outbreak" => "0",
                   "other_exp_loc_type" => "",
                   "iso_loc_country" => "",
                   "other_reason_end_of_iso" => "",
                   "sex" => "1",
                   "other_reason_quar" => "",
                   "exp_loc_street_number" => "",
                   "vacc_dt_last" => "2021-02-03",
                   "exp_loc_type_erotica" => "0",
                   "exp_loc_type_flight" => "1",
                   "exp_loc_type_hh" => "0",
                   "exp_loc_type_zoo" => "0",
                   "other_iso_loc" => "Bei Mutter zuhause",
                   "iso_loc_street" => "",
                   "case_link_yn" => "1",
                   "exp_loc_type_school" => "0",
                   "follow_up_dt" => "2021-01-05",
                   "case_link_fall_id_ism" => "",
                   "iso_loc_postal_code" => "",
                   "exp_loc_location" => "",
                   "exp_loc_type_outdoor_sport" => "0",
                   "exp_loc_type_massage" => "0",
                   "exp_loc_type_less_300_detail" => "Swiss International Airlines",
                   "sampling_dt" => "",
                   "exp_loc_type_prison" => "0",
                   "street_number" => "",
                   "fall_id_ism" => "",
                   "postal_code" => "9042",
                   "e_mail_address" => "",
                   "iso_loc_location" => "",
                   "onset_quar_dt" => "2020-10-03",
                   "exp_loc_type_less_300" => "0",
                   "exp_country" => "8215",
                   "exp_loc_type_more_300_detail" => "Swiss International Airlines"
                 },
                 %{
                   "exp_loc_type_high_school" => "0",
                   "exp_loc_name" => "BrüW",
                   "test_type" => "5",
                   "work_place_street_number" => "",
                   "exp_loc_type_choir" => "0",
                   "work_place_location" => "St. Gallen",
                   "first_name" => "Jeremy",
                   "iso_loc_street_number" => "",
                   "test_reason_quarantine" => "0",
                   "end_of_iso_dt" => "2020-10-20",
                   "case_link_ktn_internal_id" => "ca98a59b-64c5-4476-9abd-d91d2d1d24e3",
                   "test_reason_app" => "0",
                   "lab_report_dt" => "",
                   "exp_loc_type_cinema" => "0",
                   "date_of_birth" => "1992-03-27",
                   "exp_loc_type_asyl" => "0",
                   "test_result" => "3",
                   "symptom_onset_dt" => "",
                   "work_place_postal_code" => "9000",
                   "vacc_name" => "",
                   "exp_loc_type_medical" => "0",
                   "vacc_dose" => "",
                   "exp_loc_type_indoor_sport" => "0",
                   "last_name" => "Zahner",
                   "exp_loc_type_army" => "0",
                   "exp_loc_type_shop" => "0",
                   "exp_loc_dt" => ^transmission_jony_jay_date,
                   "iso_loc_type" => "1",
                   "country" => "8100",
                   "test_reason_work_screening" => "0",
                   "exp_type" => "1",
                   "test_reason_convenience" => "0",
                   "reason_end_of_iso" => "",
                   "work_place_name" => "JOSHMARTIN GmbH",
                   "exp_loc_type_yn" => "1",
                   "test_reason_cohort" => "0",
                   "exp_loc_type_work_place" => "0",
                   "exp_loc_type_school_camp" => "0",
                   "work_place_street" => "Neugasse 51",
                   "exp_loc_type_gathering" => "0",
                   "profession" => "M",
                   "reason_quar" => "contact_person",
                   "vacc_dt_first" => "",
                   "exp_loc_flightdetail" => "",
                   "exp_loc_postal_code" => "9000",
                   "vacc_yn" => "3",
                   "corr_ct_dt" => "",
                   "mobile_number" => "+41797945783",
                   "street_name" => "Hebelstrasse 20",
                   "case_link_contact_dt" => ^transmission_jony_jay_date,
                   "exp_loc_type_club" => "0",
                   "onset_iso_dt" => "2020-10-10",
                   "test_reason_symptoms" => "0",
                   "exp_loc_street" => "Torstrasse 25",
                   "ktn_internal_id" => "dd1911a3-a79f-4594-8439-5b0455569e9e",
                   "work_place_country" => "8100",
                   "other_exp_loc_type_yn" => "0",
                   "phone_number" => "",
                   "exp_loc_type_nursing_home" => "0",
                   "exp_loc_type_public_transp" => "0",
                   "exp_loc_type_more_300" => "0",
                   "exp_loc_type_child_home" => "0",
                   "quar_yn" => "1",
                   "exp_loc_type_religion" => "0",
                   "activity_mapping_yn" => "",
                   "exp_loc_type_restaurant" => "0",
                   "location" => "St. Gallen",
                   "symptoms_yn" => "0",
                   "exp_loc_type_hotel" => "0",
                   "exp_loc_type_childcare" => "0",
                   "test_reason_outbreak" => "0",
                   "other_exp_loc_type" => "",
                   "iso_loc_country" => "",
                   "other_reason_end_of_iso" => "",
                   "sex" => "1",
                   "other_reason_quar" => "",
                   "exp_loc_street_number" => "",
                   "vacc_dt_last" => "",
                   "exp_loc_type_erotica" => "0",
                   "exp_loc_type_flight" => "1",
                   "exp_loc_type_hh" => "0",
                   "exp_loc_type_zoo" => "0",
                   "other_iso_loc" => "",
                   "iso_loc_street" => "",
                   "case_link_yn" => "1",
                   "exp_loc_type_school" => "0",
                   "follow_up_dt" => "",
                   "case_link_fall_id_ism" => "",
                   "iso_loc_postal_code" => "",
                   "exp_loc_location" => "St. Gallen",
                   "exp_loc_type_outdoor_sport" => "0",
                   "exp_loc_type_massage" => "0",
                   "exp_loc_type_less_300_detail" => "BrüW",
                   "sampling_dt" => "",
                   "exp_loc_type_prison" => "0",
                   "street_number" => "",
                   "fall_id_ism" => "7000",
                   "postal_code" => "9000",
                   "e_mail_address" => "",
                   "iso_loc_location" => "",
                   "onset_quar_dt" => "2020-10-06",
                   "exp_loc_type_less_300" => "0",
                   "exp_country" => "8100",
                   "exp_loc_type_more_300_detail" => "BrüW"
                 }
               ] =
                 tenant
                 |> CaseContext.case_export(:bag_med_16122020_case)
                 |> CSV.decode!(headers: true)
                 |> Enum.to_list()
      end)
    end

    test "case_export/1 exports :bag_med_16122020_contact" do
      Repo.transaction(fn ->
        user = user_fixture()
        tenant = tenant_fixture()

        person_jony =
          person_fixture(tenant, %{
            first_name: "Jonatan",
            last_name: "Männchen",
            sex: :male,
            birth_date: ~D[1993-01-30],
            address: %{
              address: "Erlen 4",
              zip: "9042",
              place: "Speicher",
              subdivision: "AR",
              country: "CH"
            },
            contact_methods: [
              %{type: :mobile, value: "+41787245790"},
              %{type: :landline, value: "+41522330689"}
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
            ]
          })

        person_jay =
          person_fixture(tenant, %{
            address: %{
              address: "Hebelstrasse 20",
              zip: "9000",
              place: "St. Gallen",
              subdivision: "SG",
              country: "CH"
            },
            birth_date: ~D[1992-03-27],
            contact_methods: [
              %{
                type: :mobile,
                value: "+41 79 794 57 83"
              }
            ],
            external_references: [
              %{
                type: :ism_case,
                value: "7002"
              }
            ],
            first_name: "Jeremy",
            last_name: "Zahner",
            sex: :male
          })

        case_jony =
          case_fixture(person_jony, user, user, %{
            uuid: "7c8004f3-d4bc-4042-8914-265761ffc49c",
            external_references: [
              %{type: :ism_case, value: "ISM ID"}
            ],
            monitoring: %{
              location: :home,
              location_details: "Bei Mutter zuhause"
            },
            phases: [
              %{
                details: %{
                  __type__: :possible_index,
                  type: :travel
                },
                start: ~D[2020-10-03],
                end: ~D[2020-10-06]
              },
              %{
                details: %{
                  __type__: :index,
                  type: :contact_person,
                  end_reason: :healed
                },
                start: ~D[2020-10-06],
                end: ~D[2020-10-16]
              }
            ],
            clinical: %{
              has_symptoms: true,
              symptoms: [:fever],
              reasons_for_test: [:symptoms],
              test_kind: :serology,
              result: :positive,
              symptom_start: ~D[2020-10-04]
            }
          })

        case_jay =
          case_fixture(person_jay, user, user, %{
            uuid: "fc705b72-2911-46d8-93f2-5d70b982d4d8",
            monitoring: %{
              location: :home
            },
            phases: [
              %{
                details: %{
                  __type__: :possible_index,
                  type: :contact_person
                },
                start: ~D[2020-10-06],
                end: ~D[2020-10-10]
              },
              %{
                details: %{
                  __type__: :index,
                  type: :contact_person
                },
                start: ~D[2020-10-10],
                end: ~D[2020-10-20]
              }
            ],
            clinical: %{
              has_symptoms: false,
              reasons_for_test: [:contact_tracing]
            }
          })

        transmission_jony =
          transmission_fixture(%{
            date: Date.add(Date.utc_today(), -5),
            propagator_internal: nil,
            recipient_internal: true,
            recipient_case_uuid: case_jony.uuid,
            infection_place: %{
              address: %{
                country: "GB"
              },
              known: true,
              activity_mapping_executed: true,
              activity_mapping: "Seat 3A",
              type: :flight,
              name: "Swiss International Airlines",
              flight_information: "LX332"
            }
          })

        transmission_jony_jay =
          transmission_fixture(%{
            date: Date.add(Date.utc_today(), -2),
            propagator_internal: true,
            propagator_case_uuid: case_jony.uuid,
            recipient_internal: true,
            recipient_case_uuid: case_jay.uuid,
            infection_place: %{
              address: %{
                address: "Torstrasse 25",
                zip: "9000",
                place: "St. Gallen",
                subdivision: "SG",
                country: "CH"
              },
              known: true,
              activity_mapping_executed: true,
              activity_mapping: "Drank beer, kept distance to other people",
              type: :flight,
              name: "BrüW",
              flight_information: nil
            }
          })

        transmission_jony_date = Date.to_iso8601(transmission_jony.date)
        transmission_jony_jay_date = Date.to_iso8601(transmission_jony_jay.date)

        assert [
                 %{
                   "exp_loc_type_high_school" => "0",
                   "exp_loc_name" => "Swiss International Airlines",
                   "test_type" => "5",
                   "exp_loc_type_choir" => "0",
                   "first_name" => "Jonatan",
                   "test_reason_quarantine" => "0",
                   "case_link_ktn_internal_id" => "",
                   "exp_loc_type_cinema" => "0",
                   "date_of_birth" => "1993-01-30",
                   "exp_loc_type_asyl" => "0",
                   "test_result" => "1",
                   "symptom_onset_dt" => "2020-10-04",
                   "work_place_postal_code" => "9000",
                   "vacc_name" => "",
                   "exp_loc_type_medical" => "0",
                   "vacc_dose" => "",
                   "exp_loc_type_indoor_sport" => "0",
                   "last_name" => "Männchen",
                   "exp_loc_type_army" => "0",
                   "exp_loc_type_shop" => "0",
                   "exp_loc_dt" => ^transmission_jony_date,
                   "country" => "8100",
                   "exp_type" => "2",
                   "work_place_name" => "JOSHMARTIN GmbH",
                   "exp_loc_type_work_place" => "0",
                   "exp_loc_type_school_camp" => "0",
                   "exp_loc_type_gathering" => "0",
                   "profession" => "",
                   "vacc_dt_first" => "",
                   "exp_loc_flightdetail" => "LX332",
                   "exp_loc_postal_code" => "",
                   "vacc_yn" => "3",
                   "mobile_number" => "+41787245790",
                   "street_name" => "Erlen 4",
                   "case_link_contact_dt" => ^transmission_jony_date,
                   "other_test_reason" => "0",
                   "exp_loc_type_club" => "0",
                   "test_reason_symptoms" => "1",
                   "exp_loc_street" => "",
                   "ktn_internal_id" => "7c8004f3-d4bc-4042-8914-265761ffc49c",
                   "work_place_country" => "8100",
                   "other_exp_loc_type_yn" => "0",
                   "reason_end_quar" => "",
                   "phone_number" => "+41522330689",
                   "exp_loc_type_nursing_home" => "0",
                   "exp_loc_type_public_transp" => "0",
                   "exp_loc_type_more_300" => "0",
                   "exp_loc_type_child_home" => "0",
                   "exp_loc_type_religion" => "0",
                   "exp_loc_type_restaurant" => "0",
                   "location" => "Speicher",
                   "exp_loc_type_hotel" => "0",
                   "exp_loc_type_childcare" => "0",
                   "other_exp_loc_type" => "",
                   "sex" => "1",
                   "other_reason_end_quar" => "",
                   "exp_loc_street_number" => "",
                   "test_reason_quarantine_end" => "0",
                   "vacc_dt_last" => "",
                   "exp_loc_type_erotica" => "0",
                   "exp_loc_type_flight" => "1",
                   "exp_loc_type_hh" => "0",
                   "exp_loc_type_zoo" => "0",
                   "other_quar_loc_type" => "Bei Mutter zuhause",
                   "exp_loc_type_school" => "0",
                   "case_link_fall_id_ism" => "",
                   "end_quar_dt" => "2020-10-06",
                   "exp_loc_location" => "",
                   "exp_loc_type_outdoor_sport" => "0",
                   "exp_loc_type_massage" => "0",
                   "exp_loc_type_less_300_detail" => "Swiss International Airlines",
                   "sampling_dt" => "",
                   "exp_loc_type_prison" => "0",
                   "street_number" => "",
                   "postal_code" => "9042",
                   "quar_loc_type" => "1",
                   "onset_quar_dt" => "2020-10-03",
                   "exp_loc_type_less_300" => "0",
                   "exp_country" => "8215",
                   "exp_loc_type_more_300_detail" => "Swiss International Airlines"
                 },
                 %{
                   "exp_loc_type_high_school" => "0",
                   "exp_loc_name" => "BrüW",
                   "test_type" => "5",
                   "exp_loc_type_choir" => "0",
                   "first_name" => "Jeremy",
                   "test_reason_quarantine" => "0",
                   "case_link_ktn_internal_id" => "7c8004f3-d4bc-4042-8914-265761ffc49c",
                   "exp_loc_type_cinema" => "0",
                   "date_of_birth" => "1992-03-27",
                   "exp_loc_type_asyl" => "0",
                   "test_result" => "3",
                   "symptom_onset_dt" => "",
                   "work_place_postal_code" => "9000",
                   "vacc_name" => "",
                   "exp_loc_type_medical" => "0",
                   "vacc_dose" => "",
                   "exp_loc_type_indoor_sport" => "0",
                   "last_name" => "Zahner",
                   "exp_loc_type_army" => "0",
                   "exp_loc_type_shop" => "0",
                   "exp_loc_dt" => ^transmission_jony_jay_date,
                   "country" => "8100",
                   "exp_type" => "1",
                   "work_place_name" => "JOSHMARTIN GmbH",
                   "exp_loc_type_work_place" => "0",
                   "exp_loc_type_school_camp" => "0",
                   "exp_loc_type_gathering" => "0",
                   "profession" => "",
                   "vacc_dt_first" => "",
                   "exp_loc_flightdetail" => "",
                   "exp_loc_postal_code" => "9000",
                   "vacc_yn" => "3",
                   "mobile_number" => "+41797945783",
                   "street_name" => "Hebelstrasse 20",
                   "case_link_contact_dt" => ^transmission_jony_jay_date,
                   "other_test_reason" => "1",
                   "exp_loc_type_club" => "0",
                   "test_reason_symptoms" => "0",
                   "exp_loc_street" => "Torstrasse 25",
                   "ktn_internal_id" => "fc705b72-2911-46d8-93f2-5d70b982d4d8",
                   "work_place_country" => "8100",
                   "other_exp_loc_type_yn" => "0",
                   "reason_end_quar" => "",
                   "phone_number" => "",
                   "exp_loc_type_nursing_home" => "0",
                   "exp_loc_type_public_transp" => "0",
                   "exp_loc_type_more_300" => "0",
                   "exp_loc_type_child_home" => "0",
                   "exp_loc_type_religion" => "0",
                   "exp_loc_type_restaurant" => "0",
                   "location" => "St. Gallen",
                   "exp_loc_type_hotel" => "0",
                   "exp_loc_type_childcare" => "0",
                   "other_exp_loc_type" => "",
                   "sex" => "1",
                   "other_reason_end_quar" => "",
                   "exp_loc_street_number" => "",
                   "test_reason_quarantine_end" => "0",
                   "vacc_dt_last" => "",
                   "exp_loc_type_erotica" => "0",
                   "exp_loc_type_flight" => "1",
                   "exp_loc_type_hh" => "0",
                   "exp_loc_type_zoo" => "0",
                   "other_quar_loc_type" => "",
                   "exp_loc_type_school" => "0",
                   "case_link_fall_id_ism" => "",
                   "end_quar_dt" => "2020-10-10",
                   "exp_loc_location" => "St. Gallen",
                   "exp_loc_type_outdoor_sport" => "0",
                   "exp_loc_type_massage" => "0",
                   "exp_loc_type_less_300_detail" => "BrüW",
                   "sampling_dt" => "",
                   "exp_loc_type_prison" => "0",
                   "street_number" => "",
                   "postal_code" => "9000",
                   "quar_loc_type" => "1",
                   "onset_quar_dt" => "2020-10-06",
                   "exp_loc_type_less_300" => "0",
                   "exp_country" => "8100",
                   "exp_loc_type_more_300_detail" => "BrüW"
                 }
               ] =
                 tenant
                 |> CaseContext.case_export(:bag_med_16122020_contact)
                 |> CSV.decode!(headers: true)
                 |> Enum.to_list()
      end)
    end
  end

  describe "transmissions" do
    @valid_attrs %{
      date: Date.add(Date.utc_today(), -5)
    }
    @update_attrs %{
      date: Date.add(Date.utc_today(), -7)
    }
    @invalid_attrs %{
      date: nil,
      propagator_ism_id: "00000",
      propagator_internal: true,
      recipient_ism_id: nil,
      recipient_internal: nil
    }

    test "list_transmissions/0 returns all transmissions" do
      index_case = case_fixture()

      transmission =
        transmission_fixture(%{
          propagator_internal: true,
          propagator_case_uuid: index_case.uuid
        })

      assert CaseContext.list_transmissions() == [transmission]
    end

    test "get_transmission!/1 returns the transmission with given id" do
      index_case = case_fixture()

      transmission =
        transmission_fixture(%{
          propagator_internal: true,
          propagator_case_uuid: index_case.uuid
        })

      assert CaseContext.get_transmission!(transmission.uuid) == transmission
    end

    test "create_transmission/1 with valid data creates a transmission" do
      index_case = case_fixture()

      assert {:ok, %Transmission{} = transmission} =
               %{
                 propagator_internal: true,
                 propagator_case_uuid: index_case.uuid
               }
               |> Enum.into(@valid_attrs)
               |> CaseContext.create_transmission()

      assert transmission.date == Date.add(Date.utc_today(), -5)
    end

    test "create_transmission/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = CaseContext.create_transmission(@invalid_attrs)
    end

    test "update_transmission/2 with valid data updates the transmission" do
      index_case = case_fixture()

      transmission =
        transmission_fixture(%{
          propagator_internal: true,
          propagator_case_uuid: index_case.uuid
        })

      assert {:ok, %Transmission{} = transmission} =
               CaseContext.update_transmission(transmission, @update_attrs)

      assert transmission.date == Date.add(Date.utc_today(), -7)
    end

    test "update_transmission/2 with invalid data returns error changeset" do
      index_case = case_fixture()

      transmission =
        transmission_fixture(%{
          propagator_internal: true,
          propagator_case_uuid: index_case.uuid
        })

      assert {:error, %Ecto.Changeset{}} =
               CaseContext.update_transmission(transmission, @invalid_attrs)

      assert transmission == CaseContext.get_transmission!(transmission.uuid)
    end

    test "delete_transmission/1 deletes the transmission" do
      index_case = case_fixture()

      transmission =
        transmission_fixture(%{
          propagator_internal: true,
          propagator_case_uuid: index_case.uuid
        })

      assert {:ok, %Transmission{}} = CaseContext.delete_transmission(transmission)
      assert_raise Ecto.NoResultsError, fn -> CaseContext.get_transmission!(transmission.uuid) end
    end

    test "change_transmission/1 returns a transmission changeset" do
      index_case = case_fixture()

      transmission =
        transmission_fixture(%{
          propagator_internal: true,
          propagator_case_uuid: index_case.uuid
        })

      assert %Ecto.Changeset{} = CaseContext.change_transmission(transmission)
    end
  end

  describe "possible_index_submissions" do
    @valid_attrs %{
      address: %{
        address: "Helmweg 481",
        zip: "8045",
        place: "Winterthur",
        subdivision: "ZH",
        country: "CH"
      },
      birth_date: ~D[1975-07-11],
      email: "corinne.weber@gmx.ch",
      first_name: "Corinne",
      infection_place: %{
        address: %{
          address: "Torstrasse 25",
          zip: "9000",
          place: "St. Gallen",
          subdivision: "SG",
          country: "CH"
        },
        known: true,
        activity_mapping_executed: true,
        activity_mapping: "Drank beer, kept distance to other people",
        type: :club,
        name: "BrüW",
        flight_information: nil
      },
      landline: "+41 52 233 06 89",
      last_name: "Weber",
      mobile: "+41 78 898 04 51",
      sex: :female,
      transmission_date: ~D[2020-01-25]
    }

    @update_attrs %{
      address: %{
        address: "somewhere else"
      },
      birth_date: ~D[2011-05-18],
      email: "foo@gmx.net",
      first_name: "some updated first_name",
      infection_place: %{
        known: false
      },
      landline: "+41 52 123 45 67",
      last_name: "some updated last_name",
      mobile: "+41 78 123 45 67",
      sex: :male,
      transmission_date: ~D[2011-05-18]
    }
    @invalid_attrs %{
      address: nil,
      birth_date: nil,
      email: nil,
      first_name: nil,
      infection_place: nil,
      landline: nil,
      last_name: nil,
      mobile: nil,
      sex: nil,
      transmission_date: nil
    }

    test "list_possible_index_submissions/0 returns all possible_index_submissions" do
      possible_index_submission = possible_index_submission_fixture()
      assert CaseContext.list_possible_index_submissions() == [possible_index_submission]
    end

    test "get_possible_index_submission!/1 returns the possible_index_submission with given id" do
      possible_index_submission = possible_index_submission_fixture()

      assert CaseContext.get_possible_index_submission!(possible_index_submission.uuid) ==
               possible_index_submission
    end

    test "create_possible_index_submission/1 with valid data creates a possible_index_submission" do
      assert {:ok, %PossibleIndexSubmission{} = possible_index_submission} =
               CaseContext.create_possible_index_submission(case_fixture(), @valid_attrs)

      assert %{address: "Helmweg 481"} = possible_index_submission.address
      assert possible_index_submission.birth_date == ~D[1975-07-11]
      assert possible_index_submission.email == "corinne.weber@gmx.ch"
      assert possible_index_submission.first_name == "Corinne"

      assert %{
               activity_mapping: "Drank beer, kept distance to other people",
               activity_mapping_executed: true,
               address: %{
                 address: "Torstrasse 25",
                 country: "CH",
                 place: "St. Gallen",
                 subdivision: "SG",
                 zip: "9000"
               },
               flight_information: nil,
               known: true,
               name: "BrüW"
             } = possible_index_submission.infection_place

      assert possible_index_submission.landline == "+41 52 233 06 89"
      assert possible_index_submission.last_name == "Weber"
      assert possible_index_submission.mobile == "+41 78 898 04 51"
      assert possible_index_submission.sex == :female
      assert possible_index_submission.transmission_date == ~D[2020-01-25]
    end

    test "create_possible_index_submission/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} =
               CaseContext.create_possible_index_submission(case_fixture(), @invalid_attrs)
    end

    test "update_possible_index_submission/2 with valid data updates the possible_index_submission" do
      possible_index_submission = possible_index_submission_fixture()

      assert {:ok, %PossibleIndexSubmission{} = possible_index_submission} =
               CaseContext.update_possible_index_submission(
                 possible_index_submission,
                 @update_attrs
               )

      assert %{address: "somewhere else"} = possible_index_submission.address
      assert possible_index_submission.birth_date == ~D[2011-05-18]
      assert possible_index_submission.email == "foo@gmx.net"
      assert possible_index_submission.first_name == "some updated first_name"
      assert %{known: false} = possible_index_submission.infection_place
      assert possible_index_submission.landline == "+41 52 123 45 67"
      assert possible_index_submission.last_name == "some updated last_name"
      assert possible_index_submission.mobile == "+41 78 123 45 67"
      assert possible_index_submission.sex == :male
      assert possible_index_submission.transmission_date == ~D[2011-05-18]
    end

    test "update_possible_index_submission/2 with invalid data returns error changeset" do
      possible_index_submission = possible_index_submission_fixture()

      assert {:error, %Ecto.Changeset{}} =
               CaseContext.update_possible_index_submission(
                 possible_index_submission,
                 @invalid_attrs
               )

      assert possible_index_submission ==
               CaseContext.get_possible_index_submission!(possible_index_submission.uuid)
    end

    test "delete_possible_index_submission/1 deletes the possible_index_submission" do
      possible_index_submission = possible_index_submission_fixture()

      assert {:ok, %PossibleIndexSubmission{}} =
               CaseContext.delete_possible_index_submission(possible_index_submission)

      assert_raise Ecto.NoResultsError, fn ->
        CaseContext.get_possible_index_submission!(possible_index_submission.uuid)
      end
    end

    test "change_possible_index_submission/1 returns a possible_index_submission changeset" do
      possible_index_submission = possible_index_submission_fixture()

      assert %Ecto.Changeset{} =
               CaseContext.change_possible_index_submission(possible_index_submission)
    end
  end
end
