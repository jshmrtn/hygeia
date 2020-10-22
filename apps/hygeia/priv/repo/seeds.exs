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

{:ok, tenant_sg} = create_tenant(%{name: "Kanton St. Gallen"})
{:ok, _tenant_ai} = create_tenant(%{name: "Kanton Appenzell Innerrhoden"})
{:ok, tenant_ar} = create_tenant(%{name: "Kanton Appenzell Ausserrhoden"})

{:ok, _profession_hospital} = create_profession(%{name: "Spital"})
{:ok, _profession_doctor} = create_profession(%{name: "Praxis"})
{:ok, _profession_nursing_home} = create_profession(%{name: "Heim"})
{:ok, _profession_pharmacy} = create_profession(%{name: "Apotheke"})
{:ok, _profession_spitex} = create_profession(%{name: "Spitex"})
{:ok, _profession_day_care} = create_profession(%{name: "Kindertagesstätte"})
{:ok, _profession_school} = create_profession(%{name: "Volksschule"})
{:ok, _profession_high_school} = create_profession(%{name: "Oberstufe"})
{:ok, _profession_gymnasium} = create_profession(%{name: "Gymnasium / Berufsschule"})
{:ok, _porfession_security} = create_profession(%{name: "Sicherheit: Polizei, Securitas"})

{:ok, _porfession_public_transport} =
  create_profession(%{name: "ÖV: Bus, Bahn, Schiff, Bergbahn"})

{:ok, _porfession_sales} = create_profession(%{name: "Verkauf"})
{:ok, _porfession_restaurants} = create_profession(%{name: "Gastronomie / Veranstaltungen"})
{:ok, _profession_public_administration} = create_profession(%{name: "Öffentliche Verwaltung"})
{:ok, profession_office} = create_profession(%{name: "Büro"})
{:ok, _profession_construction} = create_profession(%{name: "Bau"})
{:ok, _profession_pension} = create_profession(%{name: "Rentner"})
{:ok, _profession_unemployed} = create_profession(%{name: "Arbeitssuchend"})
{:ok, _profession_other} = create_profession(%{name: "Sonstiges"})

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
        type: :possible_index,
        start: ~D[2020-10-10],
        end: ~D[2020-10-20]
      }
    ]
  })

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
      type: "Pub",
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
      type: "Flight",
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
      type: "Home",
      name: nil,
      flight_information: nil
    }
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

{:ok, _position_jm_jay} =
  create_position(%{
    organisation_uuid: organisation_jm.uuid,
    person_uuid: person_jay.uuid,
    position: "CEO"
  })
