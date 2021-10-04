defmodule Hygeia.CaseContextTest do
  @moduledoc false

  use Hygeia.DataCase

  alias Hygeia.CaseContext
  alias Hygeia.CaseContext.Address
  alias Hygeia.CaseContext.Case
  alias Hygeia.CaseContext.Case.Clinical
  alias Hygeia.CaseContext.Case.Monitoring
  alias Hygeia.CaseContext.Case.Phase
  alias Hygeia.CaseContext.ExternalReference
  alias Hygeia.CaseContext.Hospitalization
  alias Hygeia.CaseContext.Person
  alias Hygeia.CaseContext.Person.ContactMethod
  alias Hygeia.CaseContext.PossibleIndexSubmission
  alias Hygeia.CaseContext.PrematureRelease
  alias Hygeia.CaseContext.Test
  alias Hygeia.CaseContext.Transmission
  alias Hygeia.OrganisationContext.Affiliation
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
      organisation = organisation_fixture()

      assert {:ok, person} =
               CaseContext.create_person(
                 tenant,
                 Map.merge(@valid_attrs, %{
                   affiliations: [
                     %{
                       kind: :employee,
                       organisation_uuid: organisation.uuid
                     }
                   ]
                 })
               )

      assert %Person{
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
               affiliations: [
                 %Affiliation{
                   kind: :employee,
                   organisation: %Organisation{
                     name: "JOSHMARTIN GmbH",
                     address: %Address{
                       address: "Neugasse 51",
                       zip: "9000",
                       place: "St. Gallen",
                       subdivision: "SG",
                       country: "CH"
                     }
                   }
                 }
               ],
               external_references: [],
               first_name: "some first_name",
               human_readable_id: _,
               last_name: "some last_name",
               sex: :female
             } = Repo.preload(person, affiliations: [organisation: []])
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
      person = Repo.preload(person_fixture(), :affiliations)

      organisation = organisation_fixture()

      assert {:ok, person} =
               CaseContext.update_person(
                 person,
                 Map.merge(@update_attrs, %{
                   affiliations: [
                     %{
                       kind: :employee,
                       organisation_uuid: organisation.uuid
                     }
                   ]
                 })
               )

      assert %Person{
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
               affiliations: [
                 %Affiliation{
                   kind: :employee,
                   organisation: %Organisation{
                     name: "JOSHMARTIN GmbH",
                     address: %Address{
                       address: "Neugasse 51",
                       zip: "9000",
                       place: "St. Gallen",
                       subdivision: "SG",
                       country: "CH"
                     }
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
             } = Repo.preload(person, affiliations: [organisation: []])
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

      _one_person_matching = person_fixture(tenant, %{first_name: "Lars", last_name: "Müller"})

      _one_person_little_matching =
        person_fixture(tenant, %{first_name: "Lara", last_name: "Mühler"})

      _two_person_matching = person_fixture(tenant, %{first_name: "Max", last_name: "Muster"})

      _two_person_little_matching =
        person_fixture(tenant, %{first_name: "Maxi", last_name: "Muster"})

      assert [
               %Person{first_name: "Lars", last_name: "Müller"},
               %Person{first_name: "Lara", last_name: "Mühler"}
             ] = CaseContext.list_people_by_name("Lars", "Müller")

      assert [
               %Person{first_name: "Max", last_name: "Muster"},
               %Person{first_name: "Maxi", last_name: "Muster"}
             ] = CaseContext.list_people_by_name("Max", "Muster")
    end
  end

  describe "cases" do
    # ~D[2020-10-10]
    @date_case_possible_index_start Date.add(Date.utc_today(), -20)
    # ~D[2020-10-10]
    @date_case_symptom_start @date_case_possible_index_start
    # ~D[2020-10-11]
    @date_case_tested_at Date.add(@date_case_possible_index_start, 1)
    # ~D[2020-10-12]
    @date_case_laboratory_report Date.add(@date_case_tested_at, 1)
    # ~D[2020-10-12]
    @date_case_possible_index_end @date_case_laboratory_report
    # ~D[2020-10-12]
    @date_case_index_start Date.add(@date_case_possible_index_end, 1)
    # ~D[2020-10-22]
    @date_case_index_end Date.add(@date_case_index_start, 10)

    @valid_attrs %{
      complexity: :high,
      status: :first_contact,
      clinical: %{
        reasons_for_test: [:symptoms, :outbreak_examination],
        has_symptoms: true,
        symptoms: [:fever],
        symptom_start: @date_case_symptom_start
      },
      tests: [
        %{
          tested_at: @date_case_tested_at,
          laboratory_reported_at: @date_case_laboratory_report,
          kind: :pcr,
          result: :positive
        }
      ],
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
        first_contact: @date_case_index_start,
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
          start: @date_case_possible_index_start,
          end: @date_case_possible_index_end,
          quarantine_order: true
        },
        %{
          details: %{
            __type__: :index,
            end_reason: :healed
          },
          start: @date_case_index_start,
          end: @date_case_index_end,
          quarantine_order: true
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
      assert Repo.preload(CaseContext.list_cases(), tests: []) == [case]
    end

    test "get_case!/1 returns the case with given id" do
      case = case_fixture()

      assert case.uuid |> CaseContext.get_case!() |> Repo.preload(tests: []) ==
               case
    end

    test "create_case/1 with valid data creates a case" do
      tenant = %Tenant{uuid: tenant_uuid} = tenant_fixture()
      person = %Person{uuid: person_uuid} = person_fixture(tenant)
      user = %User{uuid: user_uuid} = user_fixture()
      organisation = organisation_fixture()

      assert {:ok, case} =
               CaseContext.create_case(
                 person,
                 @valid_attrs
                 |> Map.merge(%{
                   tracer_uuid: user.uuid,
                   supervisor_uuid: user.uuid,
                   hospitalizations: [
                     %{
                       start: ~D[2020-10-13],
                       end: ~D[2020-10-15],
                       organisation_uuid: organisation.uuid
                     },
                     %{
                       start: ~D[2020-10-16],
                       end: ~D[2020-10-17],
                       organisation_uuid: organisation.uuid
                     }
                   ]
                 })
                 |> put_in(
                   [:hospitalizations, Access.at(0), :organisation_uuid],
                   organisation.uuid
                 )
               )

      case = Repo.preload(case, tests: [])

      assert %Case{
               clinical: %Clinical{
                 reasons_for_test: [:symptoms, :outbreak_examination],
                 has_symptoms: true,
                 symptoms: [:fever],
                 uuid: _,
                 symptom_start: @date_case_symptom_start
               },
               complexity: :high,
               external_references: [
                 %ExternalReference{type: :ism_case, type_name: nil, uuid: _, value: "7000"},
                 %ExternalReference{type: :other, type_name: "foo", uuid: _, value: "7000"}
               ],
               hospitalizations: [
                 %Hospitalization{end: ~D[2020-10-15], start: ~D[2020-10-13], uuid: _} =
                   hospitalization,
                 %Hospitalization{end: ~D[2020-10-17], start: ~D[2020-10-16], uuid: _}
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
                 first_contact: @date_case_index_start,
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
                   end: @date_case_possible_index_end,
                   start: @date_case_possible_index_start,
                   uuid: _
                 },
                 %Phase{
                   details: %Phase.Index{
                     end_reason: :healed
                   },
                   end: @date_case_index_end,
                   start: @date_case_index_start,
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
             } = case

      assert %Hospitalization{organisation: %Organisation{}} =
               Repo.preload(hospitalization, :organisation)
    end

    test "create_case/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} =
               CaseContext.create_case(person_fixture(), @invalid_attrs)
    end

    test "update_case/2 with valid data updates the case" do
      case = Repo.preload(case_fixture(), :hospitalizations)

      assert {:ok,
              %Case{
                complexity: :low,
                status: :done
              }} = CaseContext.update_case(case, @update_attrs)
    end

    test "update_case/2 other status than hospitalization needs end date" do
      organisation = organisation_fixture()

      case =
        case_fixture(
          person_fixture(),
          user_fixture(%{iam_sub: Ecto.UUID.generate()}),
          user_fixture(%{iam_sub: Ecto.UUID.generate()}),
          %{
            status: :hospitalization,
            hospitalizations: [%{start: Date.utc_today(), organisation_uuid: organisation.uuid}]
          }
        )

      assert {:error, _changeset} = CaseContext.update_case(case, %{status: :done})
    end

    test "update_case/2 status done needs phase order decision" do
      case =
        case_fixture(
          person_fixture(),
          user_fixture(%{iam_sub: Ecto.UUID.generate()}),
          user_fixture(%{iam_sub: Ecto.UUID.generate()}),
          %{
            status: :first_contact,
            phases: [
              %{
                details: %{
                  __type__: :possible_index,
                  type: :contact_person,
                  end_reason: :converted_to_index
                }
              }
            ]
          }
        )

      case = Repo.preload(case, :hospitalizations)

      assert {:error, _changeset} = CaseContext.update_case(case, %{status: :done})
    end

    test "update_case/2 with invalid data returns error changeset" do
      case = case_fixture()
      assert {:error, %Ecto.Changeset{}} = CaseContext.update_case(case, @invalid_attrs)

      assert case ==
               case.uuid
               |> CaseContext.get_case!()
               |> Repo.preload(tests: [])
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

    test "case_export/1 exports :bag_med_16122020_case" do
      Repo.transaction(fn ->
        user = user_fixture()
        tenant = tenant_fixture()

        organisation_jm =
          organisation_fixture(%{
            name: "JOSHMARTIN GmbH",
            address: %{
              address: "Neugasse 51",
              zip: "9000",
              place: "St. Gallen",
              subdivision: "SG",
              country: "CH"
            }
          })

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
            affiliations: [
              %{
                kind: :employee,
                organisation_uuid: organisation_jm.uuid
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

        # ~D[2020-10-06]
        date_case_jony_phase_index_start = Date.utc_today()

        date_case_jony_phase_index_start_string =
          Date.to_iso8601(date_case_jony_phase_index_start)

        # ~D[2020-10-04]
        date_case_jony_symptom_start = Date.add(date_case_jony_phase_index_start, -2)
        date_case_jony_symptom_start_string = Date.to_iso8601(date_case_jony_symptom_start)
        # ~D[2020-10-05]
        date_case_jony_test = Date.add(date_case_jony_phase_index_start, -1)
        date_case_jony_test_string = Date.to_iso8601(date_case_jony_test)
        # ~D[2020-10-16]
        date_case_jony_phase_index_end = Date.add(date_case_jony_phase_index_start, 10)
        date_case_jony_phase_index_end_string = Date.to_iso8601(date_case_jony_phase_index_end)

        case_jony =
          case_fixture(person_jony, user, user, %{
            uuid: "ca98a59b-64c5-4476-9abd-d91d2d1d24e3",
            status: :next_contact_agreed,
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
                quarantine_order: false
              },
              %{
                details: %{
                  __type__: :index,
                  type: :contact_person,
                  end_reason: :healed
                },
                start: date_case_jony_phase_index_start,
                end: date_case_jony_phase_index_end,
                quarantine_order: true
              }
            ],
            clinical: %{
              has_symptoms: true,
              symptoms: [:fever],
              reasons_for_test: [:symptoms],
              symptom_start: date_case_jony_symptom_start
            },
            tests: [
              %{
                kind: :serology,
                result: :positive,
                tested_at: date_case_jony_test
              }
            ]
          })

        _note_case_jony = sms_fixture(case_jony, %{inserted_at: ~U[2021-01-05 11:55:10.783294Z]})

        # ~D[2020-10-06]
        date_case_jay_phase_possible_index_start = date_case_jony_phase_index_start

        date_case_jay_phase_possible_index_start_string =
          Date.to_iso8601(date_case_jay_phase_possible_index_start)

        # ~D[2020-10-09]
        date_case_jay_phase_possible_index_end =
          Date.add(date_case_jay_phase_possible_index_start, 4)

        # ~D[2020-10-10]
        date_case_jay_phase_index_start = Date.add(date_case_jay_phase_possible_index_end, 1)
        date_case_jay_phase_index_start_string = Date.to_iso8601(date_case_jay_phase_index_start)
        # ~D[2020-10-20]
        date_case_jay_phase_index_end = Date.add(date_case_jay_phase_index_start, 10)

        date_case_jay_phase_index_end_string = Date.to_iso8601(date_case_jay_phase_index_end)

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
                start: date_case_jay_phase_possible_index_start,
                end: date_case_jay_phase_possible_index_end,
                quarantine_order: true
              },
              %{
                details: %{
                  __type__: :index,
                  type: :contact_person
                },
                start: date_case_jay_phase_index_start,
                end: date_case_jay_phase_index_end,
                quarantine_order: true
              }
            ],
            clinical: %{
              has_symptoms: false,
              reasons_for_test: [:contact_tracing]
            },
            tests: []
          })

        transmission_jony =
          transmission_fixture(%{
            date: Date.add(Date.utc_today(), -5),
            propagator_internal: nil,
            recipient_internal: true,
            recipient_case_uuid: case_jony.uuid,
            comment: "Seat 3A",
            infection_place: %{
              address: %{
                country: "GB"
              },
              known: true,
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
            comment: "Drank beer, kept distance to other people",
            infection_place: %{
              address: %{
                address: "Torstrasse 25",
                zip: "9000",
                place: "St. Gallen",
                subdivision: "SG",
                country: "CH"
              },
              known: true,
              type: :flight,
              name: "BrüW",
              flight_information: nil
            }
          })

        transmission_jony_date = Date.to_iso8601(transmission_jony.date)
        transmission_jony_jay_date = Date.to_iso8601(transmission_jony_jay.date)

        assert [
                 %{
                   "activity_mapping_yn" => "1",
                   "case_link_contact_dt" => ^transmission_jony_date,
                   "case_link_fall_id_ism" => "",
                   "case_link_ktn_internal_id" => "",
                   "case_link_yn" => "1",
                   "corr_ct_dt" => "",
                   "country" => "8100",
                   "date_of_birth" => "1993-01-30",
                   "e_mail_address" => "",
                   "end_of_iso_dt" => ^date_case_jony_phase_index_end_string,
                   "exp_country" => "8215",
                   "exp_loc_dt" => ^transmission_jony_date,
                   "exp_loc_flightdetail" => "LX332",
                   "exp_loc_location" => "",
                   "exp_loc_name" => "Swiss International Airlines",
                   "exp_loc_postal_code" => "",
                   "exp_loc_street" => "",
                   "exp_loc_street_number" => "",
                   "exp_loc_type_army" => "0",
                   "exp_loc_type_asyl" => "0",
                   "exp_loc_type_childcare" => "0",
                   "exp_loc_type_child_home" => "0",
                   "exp_loc_type_choir" => "0",
                   "exp_loc_type_cinema" => "0",
                   "exp_loc_type_club" => "0",
                   "exp_loc_type_erotica" => "0",
                   "exp_loc_type_flight" => "1",
                   "exp_loc_type_gathering" => "0",
                   "exp_loc_type_hh" => "0",
                   "exp_loc_type_high_school" => "0",
                   "exp_loc_type_hotel" => "0",
                   "exp_loc_type_indoor_sport" => "0",
                   "exp_loc_type_less_300" => "0",
                   "exp_loc_type_less_300_detail" => "Swiss International Airlines",
                   "exp_loc_type_massage" => "0",
                   "exp_loc_type_medical" => "0",
                   "exp_loc_type_more_300" => "0",
                   "exp_loc_type_more_300_detail" => "Swiss International Airlines",
                   "exp_loc_type_nursing_home" => "0",
                   "exp_loc_type_outdoor_sport" => "0",
                   "exp_loc_type_prison" => "0",
                   "exp_loc_type_public_transp" => "0",
                   "exp_loc_type_religion" => "0",
                   "exp_loc_type_restaurant" => "0",
                   "exp_loc_type_school" => "0",
                   "exp_loc_type_school_camp" => "0",
                   "exp_loc_type_shop" => "0",
                   "exp_loc_type_work_place" => "0",
                   "exp_loc_type_yn" => "1",
                   "exp_loc_type_zoo" => "0",
                   "exp_type" => "2",
                   "fall_id_ism" => "",
                   "first_name" => "Jonatan",
                   "follow_up_dt" => "2021-01-05",
                   "iso_loc_country" => "",
                   "iso_loc_location" => "",
                   "iso_loc_postal_code" => "",
                   "iso_loc_street" => "",
                   "iso_loc_street_number" => "",
                   "iso_loc_type" => "1",
                   "ktn_internal_id" => "ca98a59b-64c5-4476-9abd-d91d2d1d24e3",
                   "lab_report_dt" => "",
                   "last_name" => "Männchen",
                   "location" => "Speicher",
                   "mobile_number" => "+41787245790",
                   "onset_iso_dt" => ^date_case_jony_phase_index_start_string,
                   "onset_quar_dt" => "",
                   "other_exp_loc_type" => "",
                   "other_exp_loc_type_yn" => "0",
                   "other_iso_loc" => "Bei Mutter zuhause",
                   "other_reason_end_of_iso" => "",
                   "other_reason_quar" => "",
                   "phone_number" => "+41522330689",
                   "postal_code" => "9042",
                   "profession" => "M",
                   "quar_yn" => "2",
                   "reason_end_of_iso" => "",
                   "reason_quar" => "2",
                   "sampling_dt" => ^date_case_jony_test_string,
                   "sex" => "1",
                   "street_name" => "Erlen 4",
                   "street_number" => "",
                   "symptom_onset_dt" => ^date_case_jony_symptom_start_string,
                   "symptoms_yn" => "1",
                   "test_reason_app" => "0",
                   "test_reason_cohort" => "0",
                   "test_reason_convenience" => "0",
                   "test_reason_outbreak" => "0",
                   "test_reason_quarantine" => "0",
                   "test_reason_symptoms" => "1",
                   "test_reason_work_screening" => "0",
                   "test_result" => "1",
                   "test_type" => "5",
                   "vacc_dose" => "2",
                   "vacc_dt_first" => "2021-01-01",
                   "vacc_dt_last" => "2021-02-03",
                   "vacc_name" => "Biontech",
                   "vacc_yn" => "1",
                   "work_place_country" => "8100",
                   "work_place_location" => "St. Gallen",
                   "work_place_name" => "JOSHMARTIN GmbH",
                   "work_place_postal_code" => "9000",
                   "work_place_street" => "Neugasse 51",
                   "work_place_street_number" => ""
                 },
                 %{
                   "activity_mapping_yn" => "3",
                   "case_link_contact_dt" => ^transmission_jony_jay_date,
                   "case_link_fall_id_ism" => "",
                   "case_link_ktn_internal_id" => "ca98a59b-64c5-4476-9abd-d91d2d1d24e3",
                   "case_link_yn" => "1",
                   "corr_ct_dt" => "",
                   "country" => "8100",
                   "date_of_birth" => "1992-03-27",
                   "e_mail_address" => "",
                   "end_of_iso_dt" => ^date_case_jay_phase_index_end_string,
                   "exp_country" => "8100",
                   "exp_loc_dt" => ^transmission_jony_jay_date,
                   "exp_loc_flightdetail" => "",
                   "exp_loc_location" => "St. Gallen",
                   "exp_loc_name" => "BrüW",
                   "exp_loc_postal_code" => "9000",
                   "exp_loc_street_number" => "",
                   "exp_loc_street" => "Torstrasse 25",
                   "exp_loc_type_army" => "0",
                   "exp_loc_type_asyl" => "0",
                   "exp_loc_type_childcare" => "0",
                   "exp_loc_type_child_home" => "0",
                   "exp_loc_type_choir" => "0",
                   "exp_loc_type_cinema" => "0",
                   "exp_loc_type_club" => "0",
                   "exp_loc_type_erotica" => "0",
                   "exp_loc_type_flight" => "1",
                   "exp_loc_type_gathering" => "0",
                   "exp_loc_type_hh" => "0",
                   "exp_loc_type_high_school" => "0",
                   "exp_loc_type_hotel" => "0",
                   "exp_loc_type_indoor_sport" => "0",
                   "exp_loc_type_less_300" => "0",
                   "exp_loc_type_less_300_detail" => "BrüW",
                   "exp_loc_type_massage" => "0",
                   "exp_loc_type_medical" => "0",
                   "exp_loc_type_more_300" => "0",
                   "exp_loc_type_more_300_detail" => "BrüW",
                   "exp_loc_type_nursing_home" => "0",
                   "exp_loc_type_outdoor_sport" => "0",
                   "exp_loc_type_prison" => "0",
                   "exp_loc_type_public_transp" => "0",
                   "exp_loc_type_religion" => "0",
                   "exp_loc_type_restaurant" => "0",
                   "exp_loc_type_school" => "0",
                   "exp_loc_type_school_camp" => "0",
                   "exp_loc_type_shop" => "0",
                   "exp_loc_type_work_place" => "0",
                   "exp_loc_type_yn" => "1",
                   "exp_loc_type_zoo" => "0",
                   "exp_type" => "1",
                   "fall_id_ism" => "7000",
                   "first_name" => "Jeremy",
                   "follow_up_dt" => "",
                   "iso_loc_country" => "",
                   "iso_loc_location" => "",
                   "iso_loc_postal_code" => "",
                   "iso_loc_street" => "",
                   "iso_loc_street_number" => "",
                   "iso_loc_type" => "1",
                   "ktn_internal_id" => "dd1911a3-a79f-4594-8439-5b0455569e9e",
                   "lab_report_dt" => "",
                   "last_name" => "Zahner",
                   "location" => "St. Gallen",
                   "mobile_number" => "+41797945783",
                   "onset_iso_dt" => ^date_case_jay_phase_index_start_string,
                   "onset_quar_dt" => ^date_case_jay_phase_possible_index_start_string,
                   "other_exp_loc_type" => "",
                   "other_exp_loc_type_yn" => "0",
                   "other_iso_loc" => "",
                   "other_reason_end_of_iso" => "",
                   "other_reason_quar" => "",
                   "phone_number" => "",
                   "postal_code" => "9000",
                   "profession" => "M",
                   "quar_yn" => "1",
                   "reason_end_of_iso" => "",
                   "reason_quar" => "1",
                   "sampling_dt" => "",
                   "sex" => "1",
                   "street_name" => "Hebelstrasse 20",
                   "street_number" => "",
                   "symptom_onset_dt" => "",
                   "symptoms_yn" => "0",
                   "test_reason_app" => "0",
                   "test_reason_cohort" => "0",
                   "test_reason_convenience" => "0",
                   "test_reason_outbreak" => "0",
                   "test_reason_quarantine" => "0",
                   "test_reason_symptoms" => "0",
                   "test_reason_work_screening" => "0",
                   "test_result" => "3",
                   "test_type" => "5",
                   "vacc_dose" => "",
                   "vacc_dt_first" => "",
                   "vacc_dt_last" => "",
                   "vacc_name" => "",
                   "vacc_yn" => "3",
                   "work_place_country" => "",
                   "work_place_location" => "",
                   "work_place_name" => "",
                   "work_place_postal_code" => "",
                   "work_place_street" => "",
                   "work_place_street_number" => ""
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

        organisation_jm =
          organisation_fixture(%{
            name: "JOSHMARTIN GmbH",
            address: %{
              address: "Neugasse 51",
              zip: "9000",
              place: "St. Gallen",
              subdivision: "SG",
              country: "CH"
            }
          })

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
            affiliations: [
              %{
                kind: :employee,
                organisation_uuid: organisation_jm.uuid
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

        # ~D[2020-10-06]
        date_case_jony_phase_index_start = Date.utc_today()

        # ~D[2020-10-04]
        date_case_jony_symptom_start = Date.add(date_case_jony_phase_index_start, -2)
        date_case_jony_symptom_start_string = Date.to_iso8601(date_case_jony_symptom_start)
        # ~D[2020-10-05]
        date_case_jony_test = Date.add(date_case_jony_phase_index_start, -1)
        date_case_jony_test_string = Date.to_iso8601(date_case_jony_test)
        # ~D[2020-10-16]
        date_case_jony_phase_index_end = Date.add(date_case_jony_phase_index_start, 10)

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
                }
              },
              %{
                details: %{
                  __type__: :index,
                  type: :contact_person,
                  end_reason: :healed
                },
                start: date_case_jony_phase_index_start,
                end: date_case_jony_phase_index_end,
                quarantine_order: true
              }
            ],
            clinical: %{
              has_symptoms: true,
              symptoms: [:fever],
              reasons_for_test: [:symptoms],
              symptom_start: date_case_jony_symptom_start
            },
            tests: [
              %{
                kind: :serology,
                result: :positive,
                tested_at: date_case_jony_test
              }
            ]
          })

        # ~D[2020-10-06]
        date_case_jay_phase_possible_index_start = date_case_jony_phase_index_start

        date_case_jay_phase_possible_index_start_string =
          Date.to_iso8601(date_case_jay_phase_possible_index_start)

        # ~D[2020-10-10]
        date_case_jay_phase_possible_index_end =
          Date.add(date_case_jay_phase_possible_index_start, 10)

        date_case_jay_phase_possible_index_end_string =
          Date.to_iso8601(date_case_jay_phase_possible_index_end)

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
                  type: :contact_person,
                  end_reason: :negative_test
                },
                start: date_case_jay_phase_possible_index_start,
                end: date_case_jay_phase_possible_index_end,
                quarantine_order: true
              }
            ],
            clinical: %{
              has_symptoms: false,
              reasons_for_test: [:contact_tracing]
            },
            tests: []
          })

        transmission_jony =
          transmission_fixture(%{
            date: Date.add(Date.utc_today(), -5),
            propagator_internal: nil,
            recipient_internal: true,
            recipient_case_uuid: case_jony.uuid,
            comment: "Seat 3A",
            infection_place: %{
              address: %{
                country: "GB"
              },
              known: true,
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
            comment: "Drank beer, kept distance to other people",
            infection_place: %{
              address: %{
                address: "Torstrasse 25",
                zip: "9000",
                place: "St. Gallen",
                subdivision: "SG",
                country: "CH"
              },
              known: true,
              type: :flight,
              name: "BrüW",
              flight_information: nil
            }
          })

        transmission_jony_date = Date.to_iso8601(transmission_jony.date)
        transmission_jony_jay_date = Date.to_iso8601(transmission_jony_jay.date)

        assert [
                 %{
                   "case_link_contact_dt" => ^transmission_jony_date,
                   "case_link_fall_id_ism" => "",
                   "case_link_ktn_internal_id" => "",
                   "country" => "8100",
                   "date_of_birth" => "1993-01-30",
                   "end_quar_dt" => "",
                   "exp_country" => "8215",
                   "exp_loc_dt" => ^transmission_jony_date,
                   "exp_loc_flightdetail" => "LX332",
                   "exp_loc_location" => "",
                   "exp_loc_name" => "Swiss International Airlines",
                   "exp_loc_postal_code" => "",
                   "exp_loc_street" => "",
                   "exp_loc_street_number" => "",
                   "exp_loc_type_army" => "0",
                   "exp_loc_type_asyl" => "0",
                   "exp_loc_type_childcare" => "0",
                   "exp_loc_type_child_home" => "0",
                   "exp_loc_type_choir" => "0",
                   "exp_loc_type_cinema" => "0",
                   "exp_loc_type_club" => "0",
                   "exp_loc_type_erotica" => "0",
                   "exp_loc_type_flight" => "1",
                   "exp_loc_type_gathering" => "0",
                   "exp_loc_type_hh" => "0",
                   "exp_loc_type_high_school" => "0",
                   "exp_loc_type_hotel" => "0",
                   "exp_loc_type_indoor_sport" => "0",
                   "exp_loc_type_less_300" => "0",
                   "exp_loc_type_less_300_detail" => "Swiss International Airlines",
                   "exp_loc_type_massage" => "0",
                   "exp_loc_type_medical" => "0",
                   "exp_loc_type_more_300" => "0",
                   "exp_loc_type_more_300_detail" => "Swiss International Airlines",
                   "exp_loc_type_nursing_home" => "0",
                   "exp_loc_type_outdoor_sport" => "0",
                   "exp_loc_type_prison" => "0",
                   "exp_loc_type_public_transp" => "0",
                   "exp_loc_type_religion" => "0",
                   "exp_loc_type_restaurant" => "0",
                   "exp_loc_type_school" => "0",
                   "exp_loc_type_school_camp" => "0",
                   "exp_loc_type_shop" => "0",
                   "exp_loc_type_work_place" => "0",
                   "exp_loc_type_zoo" => "0",
                   "exp_type" => "2",
                   "first_name" => "Jonatan",
                   "ktn_internal_id" => "7c8004f3-d4bc-4042-8914-265761ffc49c",
                   "last_name" => "Männchen",
                   "location" => "Speicher",
                   "mobile_number" => "+41787245790",
                   "onset_quar_dt" => "",
                   "other_exp_loc_type" => "",
                   "other_exp_loc_type_yn" => "0",
                   "other_quar_loc_type" => "Bei Mutter zuhause",
                   "other_reason_end_quar" => "",
                   "other_test_reason" => "0",
                   "phone_number" => "+41522330689",
                   "postal_code" => "9042",
                   "profession" => "",
                   "quar_loc_type" => "1",
                   "reason_end_quar" => "",
                   "sampling_dt" => ^date_case_jony_test_string,
                   "sex" => "1",
                   "street_name" => "Erlen 4",
                   "street_number" => "",
                   "symptom_onset_dt" => ^date_case_jony_symptom_start_string,
                   "test_reason_quarantine" => "0",
                   "test_reason_quarantine_end" => "0",
                   "test_reason_symptoms" => "1",
                   "test_result" => "1",
                   "test_type" => "5",
                   "vacc_dose" => "",
                   "vacc_dt_first" => "",
                   "vacc_dt_last" => "",
                   "vacc_name" => "",
                   "vacc_yn" => "3",
                   "work_place_country" => "8100",
                   "work_place_name" => "JOSHMARTIN GmbH",
                   "work_place_postal_code" => "9000"
                 },
                 %{
                   "case_link_contact_dt" => ^transmission_jony_jay_date,
                   "case_link_fall_id_ism" => "",
                   "case_link_ktn_internal_id" => "7c8004f3-d4bc-4042-8914-265761ffc49c",
                   "country" => "8100",
                   "date_of_birth" => "1992-03-27",
                   "end_quar_dt" => ^date_case_jay_phase_possible_index_end_string,
                   "exp_country" => "8100",
                   "exp_loc_dt" => ^transmission_jony_jay_date,
                   "exp_loc_flightdetail" => "",
                   "exp_loc_location" => "St. Gallen",
                   "exp_loc_name" => "BrüW",
                   "exp_loc_postal_code" => "9000",
                   "exp_loc_street_number" => "",
                   "exp_loc_street" => "Torstrasse 25",
                   "exp_loc_type_army" => "0",
                   "exp_loc_type_asyl" => "0",
                   "exp_loc_type_childcare" => "0",
                   "exp_loc_type_child_home" => "0",
                   "exp_loc_type_choir" => "0",
                   "exp_loc_type_cinema" => "0",
                   "exp_loc_type_club" => "0",
                   "exp_loc_type_erotica" => "0",
                   "exp_loc_type_flight" => "1",
                   "exp_loc_type_gathering" => "0",
                   "exp_loc_type_hh" => "0",
                   "exp_loc_type_high_school" => "0",
                   "exp_loc_type_hotel" => "0",
                   "exp_loc_type_indoor_sport" => "0",
                   "exp_loc_type_less_300" => "0",
                   "exp_loc_type_less_300_detail" => "BrüW",
                   "exp_loc_type_massage" => "0",
                   "exp_loc_type_medical" => "0",
                   "exp_loc_type_more_300" => "0",
                   "exp_loc_type_more_300_detail" => "BrüW",
                   "exp_loc_type_nursing_home" => "0",
                   "exp_loc_type_outdoor_sport" => "0",
                   "exp_loc_type_prison" => "0",
                   "exp_loc_type_public_transp" => "0",
                   "exp_loc_type_religion" => "0",
                   "exp_loc_type_restaurant" => "0",
                   "exp_loc_type_school" => "0",
                   "exp_loc_type_school_camp" => "0",
                   "exp_loc_type_shop" => "0",
                   "exp_loc_type_work_place" => "0",
                   "exp_loc_type_zoo" => "0",
                   "exp_type" => "1",
                   "first_name" => "Jeremy",
                   "ktn_internal_id" => "fc705b72-2911-46d8-93f2-5d70b982d4d8",
                   "last_name" => "Zahner",
                   "location" => "St. Gallen",
                   "mobile_number" => "+41797945783",
                   "onset_quar_dt" => ^date_case_jay_phase_possible_index_start_string,
                   "other_exp_loc_type" => "",
                   "other_exp_loc_type_yn" => "0",
                   "other_quar_loc_type" => "",
                   "other_reason_end_quar" => "Negative Test",
                   "other_test_reason" => "1",
                   "phone_number" => "",
                   "postal_code" => "9000",
                   "profession" => "",
                   "quar_loc_type" => "1",
                   "reason_end_quar" => "4",
                   "sampling_dt" => "",
                   "sex" => "1",
                   "street_name" => "Hebelstrasse 20",
                   "street_number" => "",
                   "symptom_onset_dt" => "",
                   "test_reason_quarantine" => "0",
                   "test_reason_quarantine_end" => "0",
                   "test_reason_symptoms" => "0",
                   "test_result" => "3",
                   "test_type" => "5",
                   "vacc_dose" => "",
                   "vacc_dt_first" => "",
                   "vacc_dt_last" => "",
                   "vacc_name" => "",
                   "vacc_yn" => "3",
                   "work_place_country" => "",
                   "work_place_name" => "",
                   "work_place_postal_code" => ""
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
      comment: "Drank beer, kept distance to other people",
      infection_place: %{
        address: %{
          address: "Torstrasse 25",
          zip: "9000",
          place: "St. Gallen",
          subdivision: "SG",
          country: "CH"
        },
        known: true,
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
      assert possible_index_submission.comment == "Drank beer, kept distance to other people"
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

  describe "hospitalizations" do
    @valid_attrs %{
      start: ~D[2011-05-18],
      end: ~D[2011-05-18]
    }

    @update_attrs %{
      start: ~D[2011-05-19],
      end: ~D[2011-05-19]
    }
    @invalid_attrs %{
      start: :invalid,
      end: "value"
    }

    test "list_hospitalizations/0 returns all hospitalizations" do
      person = person_fixture()
      tracer = user_fixture(%{iam_sub: Ecto.UUID.generate()})
      supervisor = user_fixture(%{iam_sub: Ecto.UUID.generate()})
      case = case_fixture(person, tracer, supervisor, %{hospitalizations: []})
      hospitalization = hospitalization_fixture(case)
      assert CaseContext.list_hospitalizations() == [hospitalization]
    end

    test "get_hospitalization!/1 returns the hospitalization with given id" do
      hospitalization = hospitalization_fixture()

      assert CaseContext.get_hospitalization!(hospitalization.uuid) == hospitalization
    end

    test "create_hospitalization/1 with valid data creates a hospitalization" do
      organisation = organisation_fixture()

      assert {:ok, %Hospitalization{} = hospitalization} =
               CaseContext.create_hospitalization(
                 case_fixture(),
                 Map.merge(@valid_attrs, %{organisation_uuid: organisation.uuid})
               )

      assert hospitalization.start == ~D[2011-05-18]
      assert hospitalization.end == ~D[2011-05-18]
    end

    test "create_hospitalization/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} =
               CaseContext.create_hospitalization(case_fixture(), @invalid_attrs)
    end

    test "update_hospitalization/2 with valid data updates the hospitalization" do
      hospitalization = hospitalization_fixture()

      assert {:ok, %Hospitalization{} = hospitalization} =
               CaseContext.update_hospitalization(hospitalization, @update_attrs)

      assert hospitalization.start == ~D[2011-05-19]
      assert hospitalization.end == ~D[2011-05-19]
    end

    test "update_hospitalization/2 with invalid data returns error changeset" do
      hospitalization = hospitalization_fixture()

      assert {:error, %Ecto.Changeset{}} =
               CaseContext.update_hospitalization(hospitalization, @invalid_attrs)

      assert hospitalization == CaseContext.get_hospitalization!(hospitalization.uuid)
    end

    test "delete_hospitalization/1 deletes the hospitalization" do
      hospitalization = hospitalization_fixture()

      assert {:ok, %Hospitalization{}} = CaseContext.delete_hospitalization(hospitalization)

      assert_raise Ecto.NoResultsError, fn ->
        CaseContext.get_hospitalization!(hospitalization.uuid)
      end
    end

    test "change_hospitalization/1 returns a hospitalization changeset" do
      hospitalization = hospitalization_fixture()

      assert %Ecto.Changeset{} = CaseContext.change_hospitalization(hospitalization)
    end
  end

  describe "tests" do
    @valid_attrs %{
      kind: :pcr,
      laboratory_reported_at: ~D[2010-04-17],
      reporting_unit: %{},
      result: :positive,
      sponsor: %{},
      tested_at: ~D[2010-04-17],
      reference: "123"
    }
    @update_attrs %{
      kind: :quick,
      laboratory_reported_at: ~D[2011-05-18],
      reporting_unit: %{},
      result: :negative,
      sponsor: %{},
      tested_at: ~D[2011-05-18],
      reference: "456"
    }
    @invalid_attrs %{
      kind: nil,
      laboratory_reported_at: nil,
      reporting_unit: nil,
      result: nil,
      sponsor: nil,
      tested_at: nil,
      reference: nil
    }

    test "list_tests/0 returns all tests" do
      case =
        case_fixture(
          person_fixture(),
          user_fixture(%{iam_sub: Ecto.UUID.generate()}),
          user_fixture(%{iam_sub: Ecto.UUID.generate()}),
          tests: []
        )

      test = test_fixture(case)
      assert CaseContext.list_tests() == [test]
    end

    test "get_test!/1 returns the test with given id" do
      test = test_fixture()
      assert CaseContext.get_test!(test.uuid) == test
    end

    test "create_test/1 with valid data creates a test" do
      assert {:ok, %Test{} = test} = CaseContext.create_test(case_fixture(), @valid_attrs)
      assert test.kind == :pcr
      assert test.laboratory_reported_at == ~D[2010-04-17]
      assert test.result == :positive
      assert test.tested_at == ~D[2010-04-17]
    end

    test "create_test/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = CaseContext.create_test(case_fixture(), @invalid_attrs)
    end

    test "update_test/2 with valid data updates the test" do
      test = test_fixture()
      assert {:ok, %Test{} = test} = CaseContext.update_test(test, @update_attrs)
      assert test.kind == :quick
      assert test.laboratory_reported_at == ~D[2011-05-18]
      assert test.result == :negative
      assert test.tested_at == ~D[2011-05-18]
    end

    test "update_test/2 with invalid data returns error changeset" do
      test = test_fixture()
      assert {:error, %Ecto.Changeset{}} = CaseContext.update_test(test, @invalid_attrs)
      assert test == CaseContext.get_test!(test.uuid)
    end

    test "delete_test/1 deletes the test" do
      test = test_fixture()
      assert {:ok, %Test{}} = CaseContext.delete_test(test)
      assert_raise Ecto.NoResultsError, fn -> CaseContext.get_test!(test.uuid) end
    end

    test "change_test/1 returns a test changeset" do
      test = test_fixture()
      assert %Ecto.Changeset{} = CaseContext.change_test(test)
    end
  end

  describe "premature_releases" do
    @invalid_attrs %{reason: nil}

    test "list_premature_releases/0 returns all premature_releases" do
      premature_release = premature_release_fixture()
      assert CaseContext.list_premature_releases() == [premature_release]
    end

    test "get_premature_release!/1 returns the premature_release with given id" do
      premature_release = premature_release_fixture()

      assert CaseContext.get_premature_release!(premature_release.uuid) ==
               premature_release
    end

    test "create_premature_release/1 with valid data creates a premature_release" do
      case = case_fixture()
      case_uuid = case.uuid
      phase_uuid = List.first(case.phases).uuid

      assert {:ok, %PrematureRelease{} = premature_release} =
               CaseContext.create_premature_release(case, List.first(case.phases), %{
                 reason: :immune,
                 has_documentation: true,
                 truthful: true
               })

      assert premature_release.case_uuid == case_uuid
      assert premature_release.phase_uuid == phase_uuid
      assert premature_release.reason == :immune
    end

    test "create_premature_release/1 with invalid data returns error changeset" do
      case = case_fixture()

      assert {:error, %Ecto.Changeset{}} =
               CaseContext.create_premature_release(case, List.first(case.phases), @invalid_attrs)
    end

    test "update_premature_release/2 with valid data updates the premature_release" do
      premature_release = premature_release_fixture()

      assert {:ok, %PrematureRelease{reason: :vaccinated}} =
               CaseContext.update_premature_release(premature_release, %{
                 reason: :vaccinated
               })
    end

    test "update_premature_release/2 with invalid data returns error changeset" do
      premature_release = premature_release_fixture()

      assert {:error, %Ecto.Changeset{}} =
               CaseContext.update_premature_release(premature_release, @invalid_attrs)

      assert premature_release ==
               CaseContext.get_premature_release!(premature_release.uuid)
    end

    test "delete_premature_release/1 deletes the premature_release" do
      premature_release = Repo.preload(premature_release_fixture(), :case)

      assert {:ok, %PrematureRelease{}} = CaseContext.delete_premature_release(premature_release)

      assert_raise Ecto.NoResultsError, fn ->
        CaseContext.get_premature_release!(premature_release.uuid)
      end
    end
  end
end
