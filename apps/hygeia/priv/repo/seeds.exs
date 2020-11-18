# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#

import Hygeia.CaseContext
import Hygeia.OrganisationContext
import Hygeia.TenantContext
import Hygeia.UserContext

alias Hygeia.Helpers.Versioning

Versioning.put_origin(:web)
Versioning.put_originator(:noone)

{:ok, user_1} =
  create_user(%{
    email: "user@example.com",
    display_name: "Test User",
    iam_sub: "8fe86005-b3c6-4d7c-9746-53e090d05e48"
  })

{:ok, tenant_sg} =
  create_tenant(%{
    name: "Kanton St. Gallen",
    outgoing_mail_configuration: %{
      __type__: "smtp",
      server: "smtp.postmarkapp.com",
      hostname: "joshmartin.ch",
      port: 2525,
      from_email: "hygeia@joshmartin.ch",
      username: "cc6b1d73-97ac-4a84-94c9-a729a8367ee3",
      password: "cc6b1d73-97ac-4a84-94c9-a729a8367ee3"
    }
  })

{:ok, tenant_ai} = create_tenant(%{name: "Kanton Appenzell Innerrhoden"})

{:ok, tenant_ar} =
  create_tenant(%{
    name: "Kanton Appenzell Ausserrhoden",
    outgoing_mail_configuration: %{
      __type__: "smtp",
      server: "smtp.postmarkapp.com",
      hostname: "joshmartin.ch",
      port: 2525,
      from_email: "hygeia@joshmartin.ch",
      username: "cc6b1d73-97ac-4a84-94c9-a729a8367ee3",
      password: "cc6b1d73-97ac-4a84-94c9-a729a8367ee3"
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

{:ok, infection_place_home} = create_infection_place_type(%{name: "Eigener Haushalt"})

{:ok, _infection_place_social_medical_facility} =
  create_infection_place_type(%{name: "Sozial-medizinische Einrichtung"})

{:ok, _infection_place_hospital} = create_infection_place_type(%{name: "Spital"})
{:ok, _infection_place_hotel} = create_infection_place_type(%{name: "Hotel"})
{:ok, _infection_place_asylum_center} = create_infection_place_type(%{name: "Asylzentrum"})
{:ok, infection_place_other} = create_infection_place_type(%{name: "Anderer"})

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

{:ok, organisation_kssg} =
  create_organisation(%{
    name: "Kantonsspital St. Gallen"
  })

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
        type: :ism,
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
        type: :ism,
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
    tracer_uuid: user_1.uuid,
    supervisor_uuid: user_1.uuid,
    hospitalizations: [
      %{start: ~D[2020-10-13], end: ~D[2020-10-15], organisation_uuid: organisation_kssg.uuid},
      %{start: ~D[2020-10-16], end: nil}
    ],
    clinical: %{
      reasons_for_test: [:symptoms, :outbreak_examination],
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
        tracer_uuid: user_1.uuid,
        supervisor_uuid: user_1.uuid,
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
    tracer_uuid: user_1.uuid,
    supervisor_uuid: user_1.uuid,
    external_references: [
      %{
        type: :ism,
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
    recipient_ims_id: "94327",
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
