# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#

import Hygeia.CaseContext
import Hygeia.CommunicationContext
import Hygeia.MutationContext
import Hygeia.OrganisationContext
import Hygeia.TenantContext
import Hygeia.UserContext

alias Hygeia.Helpers.Versioning
alias Hygeia.OrganisationContext.Organisation
alias Hygeia.Repo

Versioning.put_origin(:web)
Versioning.put_originator(:noone)

{tenants, _bindings} = Code.eval_file(Application.app_dir(:hygeia, "priv/repo/seeds/tenants.exs"))

tenant_sg = Enum.find(tenants, &match?(%{short_name: "SG"}, &1))
tenant_ar = Enum.find(tenants, &match?(%{short_name: "AR"}, &1))
tenant_ai = Enum.find(tenants, &match?(%{short_name: "AI"}, &1))
tenant_root = Enum.find(tenants, &match?(%{name: "Hygeia - Covid19 Tracing"}, &1))

{_hospitals, _bindings} =
  Code.eval_file(Application.app_dir(:hygeia, "priv/repo/seeds/hospitals.exs"))

{_hospitals, _bindings} =
  Code.eval_file(Application.app_dir(:hygeia, "priv/repo/seeds/schools.exs"))

{:ok, _mutation} = create_mutation(%{name: "SARS-CoV-2 - N501Y", ism_code: 1173})
{:ok, _mutation} = create_mutation(%{name: "SARS-CoV-2 - B.1.1.7", ism_code: 1174})
{:ok, _mutation} = create_mutation(%{name: "SARS-CoV-2 - N501Y & E484K", ism_code: 1180})

if System.get_env("LOAD_SAMPLE_DATA", "false") in ["1", "true"] do
  {:ok, _sedex_export_sg} =
    create_sedex_export(tenant_sg, %{
      scheduling_date: NaiveDateTime.utc_now(),
      status: :sent
    })

  {:ok, user_jony} =
    create_user(%{
      email: "maennchen@joshmartin.ch",
      display_name: "Jonatan Männchen",
      iam_sub: "76605809181649894",
      grants: [
        %{
          role: :webmaster,
          tenant_uuid: tenant_root.uuid
        },
        %{
          role: :tracer,
          tenant_uuid: tenant_sg.uuid
        },
        %{
          role: :supervisor,
          tenant_uuid: tenant_sg.uuid
        },
        %{
          role: :admin,
          tenant_uuid: tenant_sg.uuid
        },
        %{
          role: :statistics_viewer,
          tenant_uuid: tenant_sg.uuid
        },
        %{
          role: :tracer,
          tenant_uuid: tenant_ar.uuid
        },
        %{
          role: :supervisor,
          tenant_uuid: tenant_ar.uuid
        },
        %{
          role: :admin,
          tenant_uuid: tenant_ar.uuid
        },
        %{
          role: :statistics_viewer,
          tenant_uuid: tenant_ar.uuid
        },
        %{
          role: :tracer,
          tenant_uuid: tenant_ai.uuid
        },
        %{
          role: :supervisor,
          tenant_uuid: tenant_ai.uuid
        },
        %{
          role: :admin,
          tenant_uuid: tenant_ai.uuid
        },
        %{
          role: :statistics_viewer,
          tenant_uuid: tenant_ai.uuid
        }
      ]
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

  {:ok, division_jm_devs} =
    create_division(organisation_jm, %{title: "Developers", description: "People developing code"})

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
      affiliations: [
        %{
          kind: :employee,
          organisation_uuid: organisation_jm.uuid,
          division_uuid: division_jm_devs.uuid
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
      profession_category: :"74",
      profession_category_main: :M,
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
      affiliations: [
        %{
          kind: :employee,
          organisation_uuid: organisation_jm.uuid
        }
      ],
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
      profession_category: :"74",
      profession_category_main: :M,
      first_name: "Jeremy",
      last_name: "Zahner",
      sex: :male
    })

  {:ok, case_jony} =
    create_case(person_jony, %{
      complexity: :medium,
      status: :hospitalization,
      tracer_uuid: user_jony.uuid,
      supervisor_uuid: user_jony.uuid,
      hospitalizations: [
        %{start: ~D[2020-10-13], end: ~D[2020-10-15], organisation_uuid: organisation_kssg.uuid},
        %{start: ~D[2020-10-16], end: nil}
      ],
      tests: [
        %{
          tested_at: ~D[2020-10-11],
          laboratory_reported_at: ~D[2020-10-12],
          kind: :pcr,
          result: :positive
        }
      ],
      clinical: %{
        reasons_for_test: [:symptoms, :outbreak_examination],
        symptoms: [:fever],
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
    })

  random_start_date_range = Date.range(Date.add(Date.utc_today(), -100), Date.utc_today())

  if System.get_env("LOAD_STATISTICS_SEEDS", "false") in ["1", "true"] do
    {:ok, stats_people} =
      1..1000
      |> Enum.reduce(Ecto.Multi.new(), fn i, acc ->
        noga_code = Enum.random(Hygeia.EctoType.NOGA.Code.__enum_map__())
        noga_section = Hygeia.EctoType.NOGA.Code.section(noga_code)

        Ecto.Multi.insert(
          acc,
          i,
          change_new_person(Enum.random(tenants), %{
            profession_category: noga_code,
            profession_category_main: noga_section,
            first_name: "Test #{i}",
            last_name: "Test",
            sex: Enum.random(Hygeia.CaseContext.Person.Sex.__enum_map__())
          })
        )
      end)
      |> Versioning.authenticate_multi()
      |> Repo.transaction()

    stats_people =
      stats_people |> Map.values() |> Enum.filter(&is_struct(&1, Hygeia.CaseContext.Person))

    {:ok, _stats_cases} =
      stats_people
      |> Enum.with_index()
      |> Enum.reduce(Ecto.Multi.new(), fn {person, i}, acc ->
        start_date = Enum.random(random_start_date_range)
        end_date = Date.add(start_date, 10)

        index_end_reason =
          Enum.random([nil | Hygeia.CaseContext.Case.Phase.Index.EndReason.__enum_map__()])

        possible_index_end_reason =
          Enum.random([
            nil | Hygeia.CaseContext.Case.Phase.PossibleIndex.EndReason.__enum_map__()
          ])

        possible_index_type =
          Enum.random(Hygeia.CaseContext.Case.Phase.PossibleIndex.Type.__enum_map__())

        status = Enum.random(Hygeia.CaseContext.Case.Status.__enum_map__())

        phase =
          Enum.random([
            %{
              details: %{
                __type__: "index",
                end_reason: index_end_reason,
                other_end_reason:
                  case index_end_reason do
                    :other -> "ran away"
                    _other -> nil
                  end
              },
              start: start_date,
              end: end_date,
              quarantine_order:
                if status in [:done, :canceled] do
                  true
                end
            },
            %{
              details: %{
                __type__: "possible_index",
                type: possible_index_type,
                type_other:
                  case possible_index_type do
                    :other -> "likes to stay home alone"
                    _other -> nil
                  end,
                end_reason: possible_index_end_reason,
                other_end_reason:
                  case possible_index_end_reason do
                    :other -> "ran away"
                    _other -> nil
                  end
              },
              start: start_date,
              end: end_date,
              quarantine_order:
                if status in [:done, :canceled] do
                  true
                end
            }
          ])

        Ecto.Multi.insert(
          acc,
          i,
          change_new_case(person, %{
            complexity: Enum.random(Hygeia.CaseContext.Case.Complexity.__enum_map__()),
            status: status,
            tracer_uuid: user_jony.uuid,
            supervisor_uuid: user_jony.uuid,
            phases: [phase]
          })
        )
      end)
      |> Versioning.authenticate_multi()
      |> Repo.transaction()
  end

  {:ok, _note_jony} = create_note(case_jony, %{note: "zeigt symptome, geht an PCR test"})

  {:ok, _email_jony} = create_outgoing_email(case_jony, "Bleib Zuhause", "No Joke")

  {:ok, _sms_jony} = create_outgoing_sms(case_jony, "Bleib Zuhause")

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

  {:ok, _transmission_jony_jay} =
    create_transmission(%{
      date: Date.utc_today(),
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
        type: :club,
        name: "BrüW",
        flight_information: nil
      }
    })

  {:ok, _transmission_flight_jony} =
    create_transmission(%{
      date: Date.utc_today(),
      recipient_internal: true,
      recipient_case_uuid: case_jony.uuid,
      infection_place: %{
        address: nil,
        known: true,
        type: :flight,
        name: "Swiss International Airlines",
        flight_information: "LX-332"
      }
    })

  {:ok, _transmission_jony_josia} =
    create_transmission(%{
      date: Date.utc_today(),
      propagator_internal: true,
      propagator_case_uuid: case_jony.uuid,
      recipient_internal: false,
      recipient_ism_id: "94327",
      comment:
        "stayed at brothers place, were in contact for more than 15 minutes while not keeping save distance",
      infection_place: %{
        address: %{
          address: "Sunnehof 1",
          zip: "8047",
          place: "Dinhard",
          subdivision: "ZH",
          country: "CH"
        },
        known: true,
        type: :gathering,
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
