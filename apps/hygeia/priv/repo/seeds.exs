# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#

import Hygeia.CaseContext
import Hygeia.OrganisationContext
import Hygeia.TenantContext
import Hygeia.UserContext

alias Hygeia.CaseContext.InfectionPlaceType
alias Hygeia.Helpers.Versioning
alias Hygeia.OrganisationContext.Organisation
alias Hygeia.Repo

Versioning.put_origin(:web)
Versioning.put_originator(:noone)

{:ok, tenant_sg} =
  create_tenant(%{
    name: "Kanton St. Gallen",
    outgoing_mail_configuration: %{
      __type__: "smtp",
      server: "postfix-relay.postfix-relay",
      hostname: "smtp.covid19-tracing.ch",
      port: 25,
      from_email: "Info.ContactTracing@sg.ch"
    },
    outgoing_sms_configuration: %{
      __type__: "websms",
      access_token: "***REMOVED***"
    }
  })

{:ok, tenant_ai} =
  create_tenant(%{
    name: "Kanton Appenzell Innerrhoden",
    outgoing_mail_configuration: %{
      __type__: "smtp",
      server: "postfix-relay.postfix-relay",
      hostname: "smtp.covid19-tracing.ch",
      port: 25,
      from_email: "Info.ContactTracing@sg.ch"
    },
    outgoing_sms_configuration: %{
      __type__: "websms",
      access_token: "***REMOVED***"
    }
  })

{:ok, tenant_ar} =
  create_tenant(%{
    name: "Kanton Appenzell Ausserrhoden",
    outgoing_mail_configuration: %{
      __type__: "smtp",
      server: "postfix-relay.postfix-relay",
      hostname: "smtp.covid19-tracing.ch",
      port: 25,
      from_email: "Info.ContactTracing@sg.ch"
    },
    outgoing_sms_configuration: %{
      __type__: "websms",
      access_token: "***REMOVED***"
    }
  })

tenants = [
  tenant_sg,
  tenant_ai,
  tenant_ar
]

{:ok, profession_hospital} = create_profession(%{name: "Spital"})
{:ok, profession_doctor} = create_profession(%{name: "Praxis"})
{:ok, profession_nursing_home} = create_profession(%{name: "Heim"})
{:ok, profession_pharmacy} = create_profession(%{name: "Apotheke"})
{:ok, profession_spitex} = create_profession(%{name: "Spitex"})
{:ok, profession_day_care} = create_profession(%{name: "Kindertagesstätte"})
{:ok, profession_school} = create_profession(%{name: "Volksschule"})
{:ok, profession_high_school} = create_profession(%{name: "Oberstufe"})
{:ok, profession_gymnasium} = create_profession(%{name: "Gymnasium / Berufsschule"})
{:ok, profession_security} = create_profession(%{name: "Sicherheit: Polizei, Securitas"})

{:ok, profession_public_transport} = create_profession(%{name: "ÖV: Bus, Bahn, Schiff, Bergbahn"})

{:ok, profession_sales} = create_profession(%{name: "Verkauf"})
{:ok, profession_restaurants} = create_profession(%{name: "Gastronomie / Veranstaltungen"})
{:ok, profession_public_administration} = create_profession(%{name: "Öffentliche Verwaltung"})
{:ok, profession_office} = create_profession(%{name: "Büro"})
{:ok, profession_construction} = create_profession(%{name: "Bau"})
{:ok, profession_pension} = create_profession(%{name: "Rentner"})
{:ok, profession_unemployed} = create_profession(%{name: "Arbeitssuchend"})
{:ok, profession_other} = create_profession(%{name: "Sonstiges"})

professions = [
  profession_hospital,
  profession_doctor,
  profession_nursing_home,
  profession_pharmacy,
  profession_spitex,
  profession_day_care,
  profession_school,
  profession_high_school,
  profession_gymnasium,
  profession_security,
  profession_public_transport,
  profession_sales,
  profession_restaurants,
  profession_public_administration,
  profession_office,
  profession_construction,
  profession_pension,
  profession_unemployed,
  profession_other
]

[] =
  :hygeia
  |> Application.app_dir("priv/repo/seeds/infection_place_type.csv")
  |> File.stream!()
  |> CSV.decode!(headers: true)
  |> Stream.map(
    &%{
      name: &1["name"]
    }
  )
  |> Stream.map(&create_infection_place_type/1)
  |> Stream.reject(&match?({:ok, _infection_place_type}, &1))
  |> Enum.to_list()

infection_place_home = Repo.get_by!(InfectionPlaceType, name: "Eigener Haushalt")
infection_place_other = Repo.get_by!(InfectionPlaceType, name: "anderer Ort")

[] =
  :hygeia
  |> Application.app_dir("priv/repo/seeds/hospitals.csv")
  |> File.stream!()
  |> CSV.decode!(headers: true)
  |> Stream.map(
    &%{
      name: &1["name"],
      address: %{
        address: &1["address"],
        zip: &1["zip"],
        place: &1["place"],
        country: &1["country"],
        subdivision: &1["subdivision"]
      }
    }
  )
  |> Stream.map(&create_organisation/1)
  |> Stream.reject(&match?({:ok, _organisation}, &1))
  |> Enum.to_list()

if System.get_env("LOAD_SAMPLE_DATA", "false") in ["1", "true"] do
  {:ok, user_jony} =
    create_user(%{
      email: "maennchen@joshmartin.ch",
      display_name: "Jonatan Männchen",
      iam_sub: "76605809181649894"
    })

  {:ok, organisation_jm} =
    create_organisation(%{
      address: %{
        address: "Neugasse 51",
        zip: "9000",
        place: "St. Gallen",
        subdivision: "SG",
        country: "CH"
      },
      name: "JOSHMARTIN GmbH",
      notes: "Coole Astronauten"
    })

  organisation_kssg = Repo.get_by!(Organisation, name: "Kantonsspital St. Gallen")

  {:ok, person_jony} =
    create_person(tenant_ar, %{
      address: %{
        address: "Erlen 4",
        zip: "9042",
        place: "Speicher",
        subdivision: "AR",
        country: "CH"
      },
      birth_date: ~D[1993-01-30],
      contact_methods: [
        %{
          type: :mobile,
          value: "+41 78 724 57 90",
          comment: "Call only between 7 and 9 am"
        },
        %{
          type: :landline,
          value: "+41 52 233 06 89"
        },
        %{
          type: :email,
          value: "jonatan@maennchen.ch"
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
      profession_uuid: profession_office.uuid,
      first_name: "Jonatan",
      last_name: "Männchen",
      sex: :male
    })

  {:ok, person_jay} =
    create_person(tenant_sg, %{
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
      profession_uuid: profession_office.uuid,
      first_name: "Jeremy",
      last_name: "Zahner",
      sex: :male
    })

  {:ok, case_jony} =
    create_case(person_jony, %{
      complexity: :medium,
      status: :first_contact,
      tracer_uuid: user_jony.uuid,
      supervisor_uuid: user_jony.uuid,
      hospitalizations: [
        %{start: ~D[2020-10-13], end: ~D[2020-10-15], organisation_uuid: organisation_kssg.uuid},
        %{start: ~D[2020-10-16], end: nil}
      ],
      clinical: %{
        reasons_for_test: [:symptoms, :outbreak_examination],
        symptoms: [:fever],
        test: ~D[2020-10-11],
        laboratory_report: ~D[2020-10-12],
        test_kind: :pcr,
        result: :positive
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
            __type__: "possible_index",
            type: :contact_person,
            end_reason: :converted_to_index
          },
          start: ~D[2020-10-10],
          end: ~D[2020-10-12]
        },
        %{
          details: %{
            __type__: "index",
            end_reason: :healed
          },
          start: ~D[2020-10-12],
          end: ~D[2020-10-22]
        }
      ]
    })

  {:ok, _possible_index_submission_corinne} =
    create_possible_index_submission(case_jony, %{
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
        type: "Pub",
        name: "BrüW",
        flight_information: nil
      },
      landline: "+41 52 233 06 89",
      last_name: "Weber",
      mobile: "+41 78 898 04 51",
      sex: :female,
      transmission_date: ~D[2020-01-25]
    })

  random_start_date_range = Date.range(Date.add(Date.utc_today(), -100), Date.utc_today())

  if System.get_env("LOAD_STATISTICS_SEEDS", "false") in ["1", "true"] do
    for i <- 1..1000 do
      {:ok, person} =
        create_person(Enum.random(tenants), %{
          profession_uuid: Enum.random(professions).uuid,
          first_name: "Test #{i}",
          last_name: "Test",
          sex: Enum.random(Hygeia.CaseContext.Person.Sex.__enum_map__())
        })

      start_date = Enum.random(random_start_date_range)
      end_date = Date.add(start_date, 10)

      phase =
        Enum.random([
          %{
            details: %{
              __type__: "index",
              end_reason:
                Enum.random([nil | Hygeia.CaseContext.Case.Phase.Index.EndReason.__enum_map__()])
            },
            start: start_date,
            end: end_date
          },
          %{
            details: %{
              __type__: "possible_index",
              type: Enum.random(Hygeia.CaseContext.Case.Phase.PossibleIndex.Type.__enum_map__()),
              end_reason:
                Enum.random([
                  nil | Hygeia.CaseContext.Case.Phase.PossibleIndex.EndReason.__enum_map__()
                ])
            },
            start: start_date,
            end: end_date
          }
        ])

      {:ok, _index_case} =
        create_case(person, %{
          complexity: Enum.random(Hygeia.CaseContext.Case.Complexity.__enum_map__()),
          status: Enum.random(Hygeia.CaseContext.Case.Status.__enum_map__()),
          tracer_uuid: user_jony.uuid,
          supervisor_uuid: user_jony.uuid,
          phases: [phase]
        })
    end
  end

  {:ok, case_jony} = relate_case_to_organisation(case_jony, organisation_jm)

  {:ok, _protocol_entry_jony} =
    create_protocol_entry(case_jony, %{
      entry: %{__type__: "note", note: "zeigt symptome, geht an PCR test"}
    })

  {:ok, case_jay} =
    create_case(person_jay, %{
      complexity: :medium,
      status: :first_contact,
      tracer_uuid: user_jony.uuid,
      supervisor_uuid: user_jony.uuid,
      external_references: [
        %{
          type: :ism_case,
          value: "7002"
        }
      ],
      monitoring: %{
        first_contact: ~D[2020-10-12],
        location: :home,
        address: %{
          address: "Hebelstrasse 20",
          zip: "9000",
          place: "St. Gallen",
          subdivision: "SG",
          country: "CH"
        }
      },
      phases: [
        %{
          details: %{
            __type__: "possible_index",
            type: :contact_person,
            end_reason: :no_follow_up
          },
          start: ~D[2020-10-10],
          end: ~D[2020-10-20]
        }
      ]
    })

  {:ok, case_jay} = relate_case_to_organisation(case_jay, organisation_jm)

  {:ok, _transmission_jony_jay} =
    create_transmission(%{
      date: ~D[2020-10-12],
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
        type_uuid: infection_place_other.uuid,
        name: "BrüW",
        flight_information: nil
      }
    })

  {:ok, _transmission_flight_jony} =
    create_transmission(%{
      date: ~D[2020-10-12],
      recipient_internal: true,
      recipient_case_uuid: case_jony.uuid,
      infection_place: %{
        address: nil,
        known: true,
        activity_mapping_executed: false,
        activity_mapping: nil,
        type_uuid: infection_place_other.uuid,
        name: "Swiss International Airlines",
        flight_information: "LX-332"
      }
    })

  {:ok, _transmission_jony_josia} =
    create_transmission(%{
      date: ~D[2020-10-12],
      propagator_internal: true,
      propagator_case_uuid: case_jony.uuid,
      recipient_internal: false,
      recipient_ism_id: "94327",
      infection_place: %{
        address: %{
          address: "Sunnehof 1",
          zip: "8047",
          place: "Dinhard",
          subdivision: "ZH",
          country: "CH"
        },
        known: true,
        activity_mapping_executed: true,
        activity_mapping:
          "stayed at brothers place, were in contact for more than 15 minutes while not keeping save distance",
        type_uuid: infection_place_home.uuid,
        name: nil,
        flight_information: nil
      }
    })

  {:ok, _position_jm_jay} =
    create_position(%{
      organisation_uuid: organisation_jm.uuid,
      person_uuid: person_jay.uuid,
      position: "CEO"
    })
end
