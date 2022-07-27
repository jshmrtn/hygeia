defmodule Hygeia.CaseContextTest do
  @moduledoc false

  use Hygeia.DataCase

  alias Hygeia.AutoTracingContext
  alias Hygeia.AutoTracingContext.AutoTracing
  alias Hygeia.CaseContext
  alias Hygeia.CaseContext.Address
  alias Hygeia.CaseContext.Case
  alias Hygeia.CaseContext.Case.Clinical
  alias Hygeia.CaseContext.Case.Monitoring
  alias Hygeia.CaseContext.Case.Phase
  alias Hygeia.CaseContext.Entity
  alias Hygeia.CaseContext.ExternalReference
  alias Hygeia.CaseContext.Hospitalization
  alias Hygeia.CaseContext.Note
  alias Hygeia.CaseContext.Person
  alias Hygeia.CaseContext.Person.ContactMethod
  alias Hygeia.CaseContext.PossibleIndexSubmission
  alias Hygeia.CaseContext.PrematureRelease
  alias Hygeia.CaseContext.Test
  alias Hygeia.CaseContext.Transmission
  alias Hygeia.CommunicationContext.Email
  alias Hygeia.CommunicationContext.SMS
  alias Hygeia.OrganisationContext
  alias Hygeia.OrganisationContext.Affiliation
  alias Hygeia.OrganisationContext.Organisation
  alias Hygeia.OrganisationContext.Visit
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

    test "redact_person/1 redacts the person" do
      %{
        human_readable_id: person_human_readable_id,
        tenant_uuid: person_tenant_uuid,
        uuid: person_uuid
      } =
        person =
        Repo.preload(person_fixture(), [:affiliations, :employee_affiliations, :employers])

      organisation = organisation_fixture()

      assert {:ok, person} =
               CaseContext.update_person(
                 person,
                 %{
                   affiliations: [
                     %{
                       kind: :employee,
                       organisation_uuid: organisation.uuid
                     }
                   ]
                 }
               )

      assert {:ok, redacted_person} = CaseContext.redact_person(person)

      today = Date.utc_today()

      assert OrganisationContext.list_affiliations() == []

      assert %Person{
               address: nil,
               affiliations: [],
               birth_date: nil,
               contact_methods: [],
               employee_affiliations: [],
               employers: [],
               first_name: nil,
               human_readable_id: ^person_human_readable_id,
               is_vaccinated: nil,
               last_name: nil,
               profession_category: nil,
               profession_category_main: nil,
               redacted: true,
               redaction_date: ^today,
               reidentification_date: nil,
               sex: nil,
               suspected_duplicates_uuid: [],
               tenant_uuid: ^person_tenant_uuid,
               uuid: ^person_uuid
             } =
               Repo.preload(redacted_person, [:affiliations, :employee_affiliations, :employers])
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
        },
        different_location: true
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
      %Case{uuid: uuid} = case_fixture()
      assert [%Case{uuid: ^uuid}] = CaseContext.list_cases()
    end

    test "get_case!/1 returns the case with given id" do
      %Case{uuid: uuid} = case_fixture()

      assert %Case{uuid: ^uuid} = CaseContext.get_case!(uuid)
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
                 address: %{
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
      case = Repo.preload(case_fixture(), hospitalizations: [], auto_tracing: [])

      assert {:ok,
              %Case{
                complexity: :low,
                status: :done
              }} = CaseContext.update_case(case, @update_attrs)
    end

    test "update_case/2 case status can be set to closed without hospitalization end date" do
      organisation = organisation_fixture()

      case =
        Repo.preload(
          case_fixture(
            person_fixture(),
            user_fixture(%{iam_sub: Ecto.UUID.generate()}),
            user_fixture(%{iam_sub: Ecto.UUID.generate()}),
            %{
              status: :hospitalization,
              hospitalizations: [%{start: Date.utc_today(), organisation_uuid: organisation.uuid}]
            }
          ),
          :auto_tracing
        )

      assert {:ok, %Case{status: :done}} = CaseContext.update_case(case, %{status: :done})
    end

    test "update_case/2 status done needs phase order decision" do
      case =
        Repo.preload(
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
          ),
          :auto_tracing
        )

      case = Repo.preload(case, :hospitalizations)

      assert {:error, _changeset} = CaseContext.update_case(case, %{status: :done})
    end

    test "update_case/2 with invalid data returns error changeset" do
      case = CaseContext.get_case!(case_fixture().uuid)

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

    test "redact_case/1 redacts the case" do
      case_main_uuid = Ecto.UUID.generate()

      case_main =
        case_fixture(
          person_fixture(),
          user_fixture(%{iam_sub: Ecto.UUID.generate()}),
          user_fixture(%{iam_sub: Ecto.UUID.generate()}),
          %{
            uuid: case_main_uuid,
            notes: [
              %{case_uuid: case_main_uuid, note: "test"}
            ],
            visits: [
              %{
                reason: :visitor,
                last_visit_at: ~D[2020-10-15],
                unknown_organisation: %{name: "companyA"}
              }
            ],
            tests: [
              %{
                kind: :serology,
                result: :positive,
                tested_at: ~D[2020-10-25],
                reporting_unit: %{
                  address: %{
                    address: "Lagerstrasse 30",
                    country: "CH",
                    place: "Buchs SG",
                    zip: "9470"
                  },
                  division: "Buchs",
                  name: "Labormedizinisches Zentrum Dr. Risch"
                }
              }
            ]
          }
        )

      case_aux = case_fixture()

      email_fixture(case_main)
      sms_fixture(case_main)

      {:ok, _auto_tracing} = AutoTracingContext.create_auto_tracing(case_main)

      transmission_fixture(%{
        date: Date.add(Date.utc_today(), -5),
        propagator_internal: nil,
        recipient_internal: true,
        recipient_case_uuid: case_main.uuid,
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

      transmission_fixture(%{
        date: Date.add(Date.utc_today(), -2),
        propagator_internal: true,
        propagator_case_uuid: case_main.uuid,
        recipient_internal: true,
        recipient_case_uuid: case_aux.uuid,
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

      assert %Case{
               uuid: ^case_main_uuid,
               notes: [%Note{}],
               emails: [%Email{}],
               sms: [%SMS{}],
               visits: [%Visit{}],
               auto_tracing: %AutoTracing{},
               received_transmissions: [
                 %Transmission{
                   comment: "Seat 3A",
                   infection_place: %Transmission.InfectionPlace{
                     address: %{
                       country: "GB"
                     }
                   }
                 }
               ],
               propagated_transmissions: [
                 %Transmission{
                   comment: "Drank beer, kept distance to other people",
                   infection_place: %Transmission.InfectionPlace{
                     address: %{
                       address: "Torstrasse 25",
                       zip: "9000",
                       place: "St. Gallen",
                       subdivision: "SG",
                       country: "CH"
                     }
                   }
                 }
               ],
               tests: [
                 %Test{
                   tested_at: ~D[2020-10-25],
                   reporting_unit: %Entity{
                     address: %Address{
                       address: "Lagerstrasse 30",
                       country: "CH",
                       place: "Buchs SG",
                       zip: "9470"
                     },
                     division: "Buchs",
                     name: "Labormedizinisches Zentrum Dr. Risch"
                   }
                 }
               ],
               redacted: false,
               redaction_date: nil
             } =
               Repo.preload(case_main, [
                 :notes,
                 :emails,
                 :sms,
                 :visits,
                 :auto_tracing,
                 :received_transmissions,
                 :propagated_transmissions,
                 :tests
               ])

      assert {:ok, redacted_case} = CaseContext.redact_case(case_main)

      today = Date.utc_today()

      assert %Case{
               uuid: ^case_main_uuid,
               notes: [],
               emails: [],
               sms: [],
               visits: [],
               auto_tracing: nil,
               received_transmissions: [
                 %Transmission{
                   comment: nil,
                   infection_place: %Transmission.InfectionPlace{
                     address: nil
                   }
                 }
               ],
               propagated_transmissions: [
                 %Transmission{
                   comment: nil,
                   infection_place: %Transmission.InfectionPlace{
                     address: nil
                   }
                 }
               ],
               tests: [
                 %Test{
                   tested_at: nil,
                   reporting_unit: nil
                 }
               ],
               redacted: true,
               redaction_date: ^today
             } =
               Repo.preload(redacted_case, [
                 :notes,
                 :emails,
                 :sms,
                 :visits,
                 :auto_tracing,
                 :received_transmissions,
                 :propagated_transmissions,
                 :tests
               ])
    end

    test "case_export/3 exports :bag_med_16122020_case" do
      Repo.transaction(fn ->
        tenant = tenant_fixture()

        tracer =
          user_fixture(
            iam_sub: Ecto.UUID.generate(),
            grants: [%{role: :tracer, tenant_uuid: tenant.uuid}]
          )

        supervisor =
          user_fixture(
            iam_sub: Ecto.UUID.generate(),
            grants: [%{role: :supervisor, tenant_uuid: tenant.uuid}]
          )

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
            is_vaccinated: true,
            vaccination_shots: [
              %{vaccine_type: :pfizer, date: ~D[2021-01-01]},
              %{vaccine_type: :pfizer, date: ~D[2021-02-03]}
            ],
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
          case_fixture(person_jony, tracer, supervisor, %{
            uuid: "ca98a59b-64c5-4476-9abd-d91d2d1d24e3",
            status: :next_contact_agreed,
            external_references: [
              %{type: :ism_case, value: "ISM ID"}
            ],
            monitoring: %{
              location: :hotel,
              location_details: "Bei Mutter zuhause",
              address: %{
                address: "Helmweg 48",
                country: "CH",
                place: "Winterthur",
                subdivision: "ZH",
                zip: "8405"
              },
              different_location: true
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
          case_fixture(person_jay, tracer, supervisor, %{
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
                   "iso_loc_country" => "8100",
                   "iso_loc_location" => "Winterthur",
                   "iso_loc_postal_code" => "8405",
                   "iso_loc_street" => "Helmweg 48",
                   "iso_loc_street_number" => "",
                   "iso_loc_type" => "4",
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
                   "vacc_name" => "Pfizer/BioNTech (BNT162b2 / Comirnaty® / Tozinameran)",
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
                   "iso_loc_country" => "8100",
                   "iso_loc_location" => "St. Gallen",
                   "iso_loc_postal_code" => "9000",
                   "iso_loc_street" => "Hebelstrasse 20",
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
                   "vacc_dose" => "0",
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
                 |> CSV.decode!(headers: true, escape_formulas: true)
                 |> Enum.to_list()
      end)
    end

    test "case_export/3 exports :bag_med_16122020_contact" do
      Repo.transaction(fn ->
        tenant = tenant_fixture()

        tracer =
          user_fixture(
            iam_sub: Ecto.UUID.generate(),
            grants: [%{role: :tracer, tenant_uuid: tenant.uuid}]
          )

        supervisor =
          user_fixture(
            iam_sub: Ecto.UUID.generate(),
            grants: [%{role: :supervisor, tenant_uuid: tenant.uuid}]
          )

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
              %{type: :landline, value: "+41522330689"},
              %{type: :email, value: "jony@smail.com"}
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
              },
              %{type: :email, value: "jay@smail.com"}
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
          case_fixture(person_jony, tracer, supervisor, %{
            uuid: "7c8004f3-d4bc-4042-8914-265761ffc49c",
            external_references: [
              %{type: :ism_case, value: "ISM ID"}
            ],
            monitoring: %{
              location: :home,
              location_details: "Bei Mutter zuhause",
              address: %{
                address: "Helmweg 48",
                country: "CH",
                place: "Winterthur",
                subdivision: "ZH",
                zip: "8405"
              },
              different_location: true
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
          case_fixture(person_jay, tracer, supervisor, %{
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

        jony_export_contact = %{
          "case_link_contact_dt" => transmission_jony_date,
          "case_link_fall_id_ism" => "",
          "case_link_ktn_internal_id" => "",
          "country" => "8100",
          "date_of_birth" => "1993-01-30",
          "end_quar_dt" => "",
          "exp_country" => "8215",
          "exp_loc_dt" => transmission_jony_date,
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
          "sampling_dt" => date_case_jony_test_string,
          "sex" => "1",
          "street_name" => "Erlen 4",
          "street_number" => "",
          "symptom_onset_dt" => date_case_jony_symptom_start_string,
          "test_reason_quarantine" => "0",
          "test_reason_quarantine_end" => "0",
          "test_reason_symptoms" => "1",
          "test_result" => "1",
          "test_type" => "5",
          "vacc_dose" => "0",
          "vacc_dt_first" => "",
          "vacc_dt_last" => "",
          "vacc_name" => "",
          "vacc_yn" => "3",
          "work_place_country" => "8100",
          "work_place_name" => "JOSHMARTIN GmbH",
          "work_place_postal_code" => "9000"
        }

        jay_export_contact = %{
          "case_link_contact_dt" => transmission_jony_jay_date,
          "case_link_fall_id_ism" => "",
          "case_link_ktn_internal_id" => "7c8004f3-d4bc-4042-8914-265761ffc49c",
          "country" => "8100",
          "date_of_birth" => "1992-03-27",
          "end_quar_dt" => date_case_jay_phase_possible_index_end_string,
          "exp_country" => "8100",
          "exp_loc_dt" => transmission_jony_jay_date,
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
          "onset_quar_dt" => date_case_jay_phase_possible_index_start_string,
          "other_exp_loc_type" => "",
          "other_exp_loc_type_yn" => "0",
          "other_quar_loc_type" => "",
          "other_reason_end_quar" => "Negative Test",
          "other_test_reason" => "1",
          "phone_number" => "",
          "postal_code" => "9000",
          "profession" => "",
          "quar_loc_type" => "6",
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
          "vacc_dose" => "0",
          "vacc_dt_first" => "",
          "vacc_dt_last" => "",
          "vacc_name" => "",
          "vacc_yn" => "3",
          "work_place_country" => "",
          "work_place_name" => "",
          "work_place_postal_code" => ""
        }

        jony_export_contact_hygeia_extended_fields =
          Map.merge(jony_export_contact, %{
            "hygeia_case_link_region_subdivision" => "",
            "hygeia_person_email" => "jony@smail.com"
          })

        jay_export_contact_hygeia_extended_fields =
          Map.merge(jay_export_contact, %{
            "hygeia_case_link_region_subdivision" => "",
            "hygeia_person_email" => "jay@smail.com"
          })

        assert [^jony_export_contact, ^jay_export_contact] =
                 tenant
                 |> CaseContext.case_export(:bag_med_16122020_contact)
                 |> CSV.decode!(headers: true, escape_formulas: true)
                 |> Enum.to_list()

        assert [
                 ^jony_export_contact_hygeia_extended_fields,
                 ^jay_export_contact_hygeia_extended_fields
               ] =
                 tenant
                 |> CaseContext.case_export(:bag_med_16122020_contact, true)
                 |> CSV.decode!(headers: true, escape_formulas: true)
                 |> Enum.to_list()
      end)
    end
  end

  test "case_export/3 exports :breakthrough_infection" do
    Repo.transaction(fn ->
      tenant = tenant_fixture()

      tracer =
        user_fixture(
          iam_sub: Ecto.UUID.generate(),
          grants: [%{role: :tracer, tenant_uuid: tenant.uuid}]
        )

      supervisor =
        user_fixture(
          iam_sub: Ecto.UUID.generate(),
          grants: [%{role: :supervisor, tenant_uuid: tenant.uuid}]
        )

      # 8 months ago
      date_jony_vaccination_1 = Date.add(Date.utc_today(), -244)
      date_jony_vaccination_1_string = Date.to_iso8601(date_jony_vaccination_1)
      # 7 months ago
      date_jony_vaccination_2 = Date.add(Date.utc_today(), -214)
      date_jony_vaccination_2_string = Date.to_iso8601(date_jony_vaccination_2)
      # 1 month ago
      date_jony_vaccination_3 = Date.add(Date.utc_today(), -30)
      date_jony_vaccination_3_string = Date.to_iso8601(date_jony_vaccination_3)

      person_jony =
        person_fixture(tenant, %{
          uuid: "13eaaf3a-11e9-4f8b-b0e0-b52a65facd94",
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
          is_vaccinated: true,
          vaccination_shots: [
            %{vaccine_type: :moderna, date: date_jony_vaccination_1},
            %{vaccine_type: :moderna, date: date_jony_vaccination_2},
            %{vaccine_type: :pfizer, date: date_jony_vaccination_3}
          ]
        })

      person_jan =
        person_fixture(tenant, %{
          uuid: "c4524c2a-1cee-4fe6-959d-4ca18e658ec3",
          first_name: "Jan",
          last_name: "Mrnak"
        })

      # 10 months ago
      date_case_jony_before_vaccination_phase_index_start = Date.add(Date.utc_today(), -300)

      date_case_jony_before_vaccination_test =
        Date.add(date_case_jony_before_vaccination_phase_index_start, -1)

      date_case_jony_before_vaccination_phase_index_end =
        Date.add(date_case_jony_before_vaccination_phase_index_start, 10)

      case_fixture(person_jony, tracer, supervisor, %{
        uuid: "2c11959a-c631-4b66-b64c-fee8fd4aed1c",
        phases: [
          %{
            details: %{
              __type__: :index,
              end_reason: :healed
            },
            start: date_case_jony_before_vaccination_phase_index_start,
            end: date_case_jony_before_vaccination_phase_index_end,
            quarantine_order: true
          }
        ],
        tests: [
          %{
            kind: :pcr,
            result: :positive,
            tested_at: date_case_jony_before_vaccination_test
          }
        ],
        clinical: nil
      })

      # 3 months ago
      date_case_jony_after_vaccination_phase_index_start = Date.add(Date.utc_today(), -90)

      date_case_jony_after_vaccination_symptom_start =
        Date.add(date_case_jony_after_vaccination_phase_index_start, -2)

      date_case_jony_after_vaccination_symptom_start_string =
        Date.to_iso8601(date_case_jony_after_vaccination_symptom_start)

      date_case_jony_after_vaccination_test =
        Date.add(date_case_jony_after_vaccination_phase_index_start, -1)

      date_case_jony_after_vaccination_test_string =
        Date.to_iso8601(date_case_jony_after_vaccination_test)

      date_case_jony_after_vaccination_phase_index_end =
        Date.add(date_case_jony_after_vaccination_phase_index_start, 10)

      case_fixture(person_jony, tracer, supervisor, %{
        uuid: "86438dad-dc4b-4b87-9332-388cd8f62546",
        phases: [
          %{
            details: %{
              __type__: :index,
              end_reason: :healed
            },
            start: date_case_jony_after_vaccination_phase_index_start,
            end: date_case_jony_after_vaccination_phase_index_end,
            quarantine_order: true
          }
        ],
        clinical: %{
          has_symptoms: true,
          symptoms: [:fever, :cough],
          symptom_start: date_case_jony_after_vaccination_symptom_start
        },
        tests: [
          %{
            kind: :pcr,
            result: :positive,
            tested_at: date_case_jony_after_vaccination_test
          }
        ]
      })

      # 3 months ago
      date_case_jan_no_vaccination_phase_index_start = Date.add(Date.utc_today(), -90)

      date_case_jan_no_vaccination_phase_index_end =
        Date.add(date_case_jan_no_vaccination_phase_index_start, 10)

      case_fixture(person_jan, tracer, supervisor, %{
        uuid: "e98ace13-83d6-45d7-8ae9-9dd9de76ee95",
        phases: [
          %{
            details: %{
              __type__: :index,
              end_reason: :healed
            },
            start: date_case_jan_no_vaccination_phase_index_start,
            end: date_case_jan_no_vaccination_phase_index_end,
            quarantine_order: true
          }
        ]
      })

      assert [
               %{
                 "Birth Date" => "1993-01-30",
                 "Case Human Readable ID" => "componet-contingentis-73",
                 "Case ID" => "86438dad-dc4b-4b87-9332-388cd8f62546",
                 "Firstname" => "Jonatan",
                 "Last Test Date" => ^date_case_jony_after_vaccination_test_string,
                 "Lastname" => "Männchen",
                 "Person Human Readable ID" => "virginum-praedicabas-50",
                 "Person ID" => "13eaaf3a-11e9-4f8b-b0e0-b52a65facd94",
                 "Symptom Start Date" => ^date_case_jony_after_vaccination_symptom_start_string,
                 "Symptoms" => "Fever, Cough",
                 "Vaccination 1st Jab Date" => ^date_jony_vaccination_1_string,
                 "Vaccination 1st Jab Name" =>
                   "Moderna (mRNA-1273 / Spikevax / COVID-19 vaccine Moderna)",
                 "Vaccination 2nd Jab Date" => ^date_jony_vaccination_2_string,
                 "Vaccination 2nd Jab Name" =>
                   "Moderna (mRNA-1273 / Spikevax / COVID-19 vaccine Moderna)",
                 "Vaccination 3rd Jab Date" => ^date_jony_vaccination_3_string,
                 "Vaccination 3rd Jab Name" =>
                   "Pfizer/BioNTech (BNT162b2 / Comirnaty® / Tozinameran)",
                 "Vaccination 4th Jab Date" => "",
                 "Vaccination 4th Jab Name" => ""
               }
             ] =
               tenant
               |> CaseContext.case_export(:breakthrough_infection)
               |> CSV.decode!(headers: true, escape_formulas: true)
               |> Enum.to_list()
    end)
  end

  test "case_export/3 exports :breakthrough_infection even with empty person vaccination" do
    Repo.transaction(fn ->
      tenant = tenant_fixture()

      tracer =
        user_fixture(
          iam_sub: Ecto.UUID.generate(),
          grants: [%{role: :tracer, tenant_uuid: tenant.uuid}]
        )

      supervisor =
        user_fixture(
          iam_sub: Ecto.UUID.generate(),
          grants: [%{role: :supervisor, tenant_uuid: tenant.uuid}]
        )

      person_jony =
        person_fixture(tenant, %{
          uuid: "13eaaf3a-11e9-4f8b-b0e0-b52a65facd94",
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
          vaccination_shots: []
        })

      # 3 months ago
      date_case_jony_after_vaccination_phase_index_start = Date.add(Date.utc_today(), -90)

      date_case_jony_after_vaccination_test =
        Date.add(date_case_jony_after_vaccination_phase_index_start, -1)

      date_case_jony_after_vaccination_phase_index_end =
        Date.add(date_case_jony_after_vaccination_phase_index_start, 10)

      case_fixture(person_jony, tracer, supervisor, %{
        uuid: "86438dad-dc4b-4b87-9332-388cd8f62546",
        phases: [
          %{
            details: %{
              __type__: :index,
              end_reason: :healed
            },
            start: date_case_jony_after_vaccination_phase_index_start,
            end: date_case_jony_after_vaccination_phase_index_end,
            quarantine_order: true
          }
        ],
        clinical: %{
          has_symptoms: true,
          symptoms: [:fever, :cough],
          symptom_start: nil
        },
        tests: [
          %{
            kind: :pcr,
            result: :positive,
            tested_at: date_case_jony_after_vaccination_test
          }
        ]
      })

      assert [] =
               tenant
               |> CaseContext.case_export(:breakthrough_infection)
               |> CSV.decode!(headers: true, escape_formulas: true)
               |> Enum.to_list()
    end)
  end

  describe "transmissions" do
    @valid_attrs %{
      date: Date.add(Date.utc_today(), -5),
      type: :contact_person
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

  describe "vaccination_shot_validity" do
    test "counts mixed mrna vaccinations" do
      vaccination_1_date = Date.add(Date.utc_today(), -180)
      vaccination_2_date = Date.add(Date.utc_today(), -150)

      validity =
        Date.range(
          vaccination_2_date,
          vaccination_2_date |> Date.add(-1) |> Cldr.Calendar.plus(:years, 1)
        )

      person =
        person_fixture(tenant_fixture(), %{
          is_vaccinated: true,
          vaccination_shots: [
            %{
              vaccine_type: :moderna,
              date: vaccination_1_date
            },
            %{
              vaccine_type: :pfizer,
              date: vaccination_2_date
            }
          ]
        })

      assert %Person{
               vaccination_shot_validities: [
                 %Person.VaccinationShot.Validity{
                   range: ^validity
                 }
               ]
             } = Repo.preload(person, :vaccination_shot_validities)
    end

    test "counts janssen vaccination" do
      vaccination_date = Date.add(Date.utc_today(), -180)

      validity_start_date = Date.add(vaccination_date, 22)

      validity =
        Date.range(
          validity_start_date,
          validity_start_date |> Date.add(-1) |> Cldr.Calendar.plus(:years, 1)
        )

      person =
        person_fixture(tenant_fixture(), %{
          is_vaccinated: true,
          vaccination_shots: [
            %{
              vaccine_type: :janssen,
              date: vaccination_date
            }
          ]
        })

      assert %Person{
               vaccination_shot_validities: [
                 %Person.VaccinationShot.Validity{
                   range: ^validity
                 }
               ]
             } = Repo.preload(person, :vaccination_shot_validities)
    end

    test "counts one mrna vaccination after external convalescence" do
      vaccination_date = Date.add(Date.utc_today(), -180)

      validity =
        Date.range(
          vaccination_date,
          vaccination_date |> Date.add(-1) |> Cldr.Calendar.plus(:years, 1)
        )

      person =
        person_fixture(tenant_fixture(), %{
          convalescent_externally: true,
          is_vaccinated: true,
          vaccination_shots: [
            %{
              vaccine_type: :moderna,
              date: vaccination_date
            }
          ]
        })

      assert %Person{
               vaccination_shot_validities: [
                 %Person.VaccinationShot.Validity{
                   range: ^validity
                 }
               ]
             } = Repo.preload(person, :vaccination_shot_validities)
    end

    test "counts one mrna vaccination after internal convalescence" do
      vaccination_date = Cldr.Calendar.plus(Date.utc_today(), :months, -1)

      order_date = DateTime.new!(Cldr.Calendar.plus(Date.utc_today(), :months, -5), ~T[12:00:00])
      order_start_date = DateTime.to_date(order_date)
      order_end_date = Date.add(order_start_date, 10)

      validity =
        Date.range(
          vaccination_date,
          vaccination_date |> Date.add(-1) |> Cldr.Calendar.plus(:years, 1)
        )

      person =
        person_fixture(tenant_fixture(), %{
          is_vaccinated: true,
          vaccination_shots: [
            %{
              vaccine_type: :moderna,
              date: vaccination_date
            }
          ]
        })

      _case =
        case_fixture(person, nil, nil, %{
          phases: [
            %{
              details: %{__type__: :index},
              order_date: order_date,
              quarantine_order: true,
              start: order_start_date,
              end: order_end_date
            }
          ],
          tests: [],
          clinical: nil
        })

      assert %Person{
               vaccination_shot_validities: [
                 %Person.VaccinationShot.Validity{
                   range: ^validity
                 }
               ]
             } = Repo.preload(person, :vaccination_shot_validities)
    end

    # https://www.bag.admin.ch/bag/de/home/krankheiten/ausbrueche-epidemien-pandemien/aktuelle-ausbrueche-epidemien/novel-cov/covid-zertifikat/covid-zertifikat-erhalt-gueltigkeit.html#-86956486
    test "counts one mrna vaccination before internal convalescence" do
      vaccination_date = Cldr.Calendar.plus(Date.utc_today(), :months, -4)

      order_date = DateTime.new!(Cldr.Calendar.plus(Date.utc_today(), :months, -2), ~T[12:00:00])
      order_start_date = DateTime.to_date(order_date)
      order_end_date = Date.add(order_start_date, 10)

      validity =
        Date.range(
          order_end_date,
          order_end_date |> Date.add(-1) |> Cldr.Calendar.plus(:years, 1)
        )

      person =
        person_fixture(tenant_fixture(), %{
          is_vaccinated: true,
          vaccination_shots: [
            %{
              vaccine_type: :moderna,
              date: vaccination_date
            }
          ]
        })

      _case =
        case_fixture(person, nil, nil, %{
          phases: [
            %{
              details: %{__type__: :index},
              order_date: order_date,
              quarantine_order: true,
              start: order_start_date,
              end: order_end_date
            }
          ],
          tests: [],
          clinical: nil
        })

      assert %Person{
               vaccination_shot_validities: [
                 %Person.VaccinationShot.Validity{
                   range: ^validity
                 }
               ]
             } = Repo.preload(person, :vaccination_shot_validities)
    end

    # https://www.bag.admin.ch/bag/de/home/krankheiten/ausbrueche-epidemien-pandemien/aktuelle-ausbrueche-epidemien/novel-cov/haeufig-gestellte-fragen.html?faq-url=/covid/de/impfung/ich-bin-genesen-wie-viele-impfdosen-soll-ich-erhalten
    # > In folgenden Fällen müssen zwei Impfdosen verabreicht werden:
    # > Die bestätigte Coronavirus-Infektion liegt weniger als 4 Wochen zurück.
    test "doesn't count one mrna vaccination shortly before internal convalescence" do
      vaccination_date = Cldr.Calendar.plus(Date.utc_today(), :weeks, -5)

      order_date = DateTime.new!(Cldr.Calendar.plus(Date.utc_today(), :weeks, -4), ~T[12:00:00])
      order_start_date = DateTime.to_date(order_date)
      order_end_date = Date.add(order_start_date, 10)

      person =
        person_fixture(tenant_fixture(), %{
          is_vaccinated: true,
          vaccination_shots: [
            %{
              vaccine_type: :moderna,
              date: vaccination_date
            }
          ]
        })

      _case =
        case_fixture(person, nil, nil, %{
          phases: [
            %{
              details: %{__type__: :index},
              order_date: order_date,
              quarantine_order: true,
              start: order_start_date,
              end: order_end_date
            }
          ],
          tests: [],
          clinical: nil
        })

      assert %Person{vaccination_shot_validities: []} =
               Repo.preload(person, :vaccination_shot_validities)
    end
  end
end
