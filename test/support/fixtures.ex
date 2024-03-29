defmodule Hygeia.Fixtures do
  @moduledoc """
  Model Fixtures Helper
  """

  alias Hygeia.AutoTracingContext
  alias Hygeia.AutoTracingContext.AutoTracing
  alias Hygeia.CaseContext
  alias Hygeia.CaseContext.Case
  alias Hygeia.CaseContext.Hospitalization
  alias Hygeia.CaseContext.Note
  alias Hygeia.CaseContext.Person
  alias Hygeia.CaseContext.PossibleIndexSubmission
  alias Hygeia.CaseContext.PrematureRelease
  alias Hygeia.CaseContext.Test
  alias Hygeia.CaseContext.Transmission
  alias Hygeia.CommunicationContext
  alias Hygeia.CommunicationContext.Email
  alias Hygeia.CommunicationContext.SMS
  alias Hygeia.ImportContext
  alias Hygeia.ImportContext.Import
  alias Hygeia.ImportContext.Row
  alias Hygeia.MutationContext
  alias Hygeia.MutationContext.Mutation
  alias Hygeia.NotificationContext
  alias Hygeia.NotificationContext.Notification
  alias Hygeia.OrganisationContext
  alias Hygeia.OrganisationContext.Affiliation
  alias Hygeia.OrganisationContext.Division
  alias Hygeia.OrganisationContext.Organisation
  alias Hygeia.OrganisationContext.Visit
  alias Hygeia.Repo
  alias Hygeia.RiskCountryContext
  alias Hygeia.RiskCountryContext.RiskCountry
  alias Hygeia.SystemMessageContext
  alias Hygeia.SystemMessageContext.SystemMessage
  alias Hygeia.TenantContext
  alias Hygeia.TenantContext.SedexExport
  alias Hygeia.TenantContext.Tenant
  alias Hygeia.UserContext
  alias Hygeia.UserContext.User

  @valid_attrs %{name: "some name", case_management_enabled: true}

  @spec tenant_fixture(attrs :: Hygeia.ecto_changeset_params()) :: Tenant.t()
  def tenant_fixture(attrs \\ %{}) do
    {:ok, tenant} =
      attrs
      |> Enum.into(@valid_attrs)
      |> TenantContext.create_tenant()

    tenant
  end

  @valid_attrs %{
    display_name: "Wilfred Walrus",
    email: "wilfred.walrus@example.com",
    iam_sub: "8fe86005-b3c6-4d7c-9746-53e090d05e48"
  }

  @spec user_fixture(attrs :: Hygeia.ecto_changeset_params()) :: User.t()
  def user_fixture(attrs \\ %{}) do
    attrs = Enum.into(attrs, @valid_attrs)

    attrs =
      if Map.has_key?(attrs, :grants) do
        attrs
      else
        tenant = tenant_fixture()
        Map.put_new(attrs, :grants, [%{role: :tracer, tenant_uuid: tenant.uuid}])
      end

    {:ok, user} = UserContext.create_user(attrs)

    user
  end

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
    first_name: "some first_name",
    last_name: "some last_name",
    sex: :female
  }

  @spec person_fixture(tenant :: Tenant.t(), attrs :: Hygeia.ecto_changeset_params()) ::
          Person.t()
  def person_fixture(tenant \\ tenant_fixture(), attrs \\ %{}) do
    {:ok, person} = CaseContext.create_person(tenant, Enum.into(attrs, @valid_attrs))

    person
  end

  defp case_fixture_attrs do
    # ~D[2020-10-10]
    date_case_possible_index_start = Date.add(Date.utc_today(), -5)
    # ~D[2020-10-10]
    date_case_symptom_start = date_case_possible_index_start
    # ~D[2020-10-11]
    date_case_tested_at = Date.add(date_case_possible_index_start, 1)
    # ~D[2020-10-12]
    date_case_laboratory_report = Date.add(date_case_tested_at, 1)
    # ~D[2020-10-12]
    date_case_possible_index_end = date_case_laboratory_report
    # ~D[2020-10-12]
    date_case_index_start = Date.add(date_case_possible_index_end, 1)
    # ~D[2020-10-22]
    date_case_index_end = Date.add(date_case_index_start, 10)

    %{
      complexity: :medium,
      status: :first_contact,
      # hospitalizations: [
      #   %{start: ~D[2020-10-13], end: ~D[2020-10-15]},
      #   %{start: ~D[2020-10-16], end: ~D[2020-10-17]}
      # ],
      tests: [
        %{
          tested_at: date_case_tested_at,
          laboratory_reported_at: date_case_laboratory_report,
          kind: :pcr,
          result: :positive
        }
      ],
      clinical: %{
        reasons_for_test: [:symptoms, :outbreak_examination],
        symptoms: [:fever],
        symptom_start: date_case_symptom_start,
        has_symptoms: true
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
        first_contact: date_case_index_start,
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
          start: date_case_possible_index_start,
          end: date_case_possible_index_end,
          quarantine_order: true
        },
        %{
          details: %{
            __type__: :index,
            end_reason: :healed
          },
          start: date_case_index_start,
          end: date_case_index_end,
          quarantine_order: true
        }
      ]
    }
  end

  @spec case_fixture(
          person :: Person.t(),
          tracer :: User.t(),
          supervisor :: User.t(),
          attrs :: Hygeia.ecto_changeset_params()
        ) :: Case.t()
  def case_fixture(
        person \\ person_fixture(),
        tracer \\ user_fixture(%{iam_sub: Ecto.UUID.generate()}),
        supervisor \\ user_fixture(%{iam_sub: Ecto.UUID.generate()}),
        attrs \\ %{}
      ) do
    tracer_uuid =
      case tracer do
        nil ->
          nil

        %User{} ->
          tracer = Repo.preload(tracer, :grants)

          {:ok, tracer} =
            UserContext.update_user(tracer, %{
              grants: [%{role: :tracer, tenant_uuid: person.tenant_uuid}]
            })

          tracer.uuid
      end

    supervisor_uuid =
      case supervisor do
        nil ->
          nil

        %User{} ->
          supervisor = Repo.preload(supervisor, :grants)

          {:ok, supervisor} =
            UserContext.update_user(supervisor, %{
              grants: [%{role: :supervisor, tenant_uuid: person.tenant_uuid}]
            })

          supervisor.uuid
      end

    {:ok, case} =
      CaseContext.create_case(
        person,
        attrs
        |> Enum.into(case_fixture_attrs())
        |> Map.put_new(:tracer_uuid, tracer_uuid)
        |> Map.put_new(:supervisor_uuid, supervisor_uuid)
      )

    case
  end

  @valid_attrs %{
    address: %{
      address: "Neugasse 51",
      zip: "9000",
      place: "St. Gallen",
      subdivision: "SG",
      country: "CH"
    },
    name: "JOSHMARTIN GmbH",
    notes: "Coole Astronauten"
  }
  @spec organisation_fixture(attrs :: Hygeia.ecto_changeset_params()) :: Organisation.t()
  def organisation_fixture(attrs \\ %{}) do
    {:ok, organisation} =
      attrs
      |> Enum.into(@valid_attrs)
      |> OrganisationContext.create_organisation()

    organisation
  end

  @valid_attrs %{
    reason: :visitor,
    last_visit_at: Date.add(Date.utc_today(), -5),
    unknown_organisation: %{
      address: %{
        address: "Torstrasse 25",
        zip: "9000",
        place: "St. Gallen",
        subdivision: "SG",
        country: "CH"
      },
      name: "TestInc"
    }
  }

  @doc """
  Generate a visit.
  """
  @spec visit_fixture(case :: Case.t(), attrs :: Hygeia.ecto_changeset_params()) :: Visit.t()
  def visit_fixture(case, attrs \\ %{}) do
    {:ok, visit} = Hygeia.OrganisationContext.create_visit(case, Enum.into(attrs, @valid_attrs))

    visit
  end

  @valid_attrs %{
    type: :contact_person,
    date: Date.add(Date.utc_today(), -5),
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
  }

  @spec transmission_fixture(attrs :: Hygeia.ecto_changeset_params()) :: Transmission.t()
  def transmission_fixture(attrs \\ %{}) do
    {:ok, transmission} =
      attrs
      |> Enum.into(@valid_attrs)
      |> CaseContext.create_transmission()

    transmission
  end

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
    transmission_date: ~D[2020-01-25],
    employer: "Unknown GmbH"
  }

  @spec possible_index_submission_fixture(
          case :: Case.t(),
          attrs :: Hygeia.ecto_changeset_params()
        ) :: PossibleIndexSubmission.t()
  def possible_index_submission_fixture(case \\ case_fixture(), attrs \\ %{}) do
    {:ok, possible_index_submission} =
      CaseContext.create_possible_index_submission(case, Enum.into(attrs, @valid_attrs))

    possible_index_submission
  end

  @valid_attrs %{
    direction: :outgoing,
    last_try: ~N[2010-04-17 14:00:00],
    message: "some message",
    status: :success
  }

  @spec email_fixture(case :: Case.t(), attrs :: Hygeia.ecto_changeset_params()) :: Email.t()
  def email_fixture(case \\ case_fixture(), attrs \\ %{}) do
    {:ok, email} = CommunicationContext.create_email(case, Enum.into(attrs, @valid_attrs))

    email
  end

  @valid_attrs %{
    direction: :outgoing,
    last_try: ~N[2010-04-17 14:00:00],
    message: "some message",
    number: "+41 78 724 57 90",
    status: :success
  }

  @spec sms_fixture(case :: Case.t(), attrs :: Hygeia.ecto_changeset_params()) :: SMS.t()
  def sms_fixture(case \\ case_fixture(), attrs \\ %{}) do
    {:ok, sms} = CommunicationContext.create_sms(case, Enum.into(attrs, @valid_attrs))

    sms
  end

  @valid_attrs %{
    note: "some note"
  }

  @spec note_fixture(case :: Case.t(), attrs :: Hygeia.ecto_changeset_params()) :: Note.t()
  def note_fixture(case \\ case_fixture(), attrs \\ %{}) do
    {:ok, note} = CaseContext.create_note(case, Enum.into(attrs, @valid_attrs))

    note
  end

  @valid_attrs %{
    end_date: ~N[2010-04-17 14:00:00],
    text: "some message",
    start_date: ~N[2010-04-17 10:00:00],
    roles: ["admin"]
  }

  @spec system_message_fixture(attrs :: Hygeia.ecto_changeset_params()) :: SystemMessage.t()
  def system_message_fixture(attrs \\ %{}) do
    {:ok, system_message} =
      attrs
      |> Enum.into(@valid_attrs)
      |> SystemMessageContext.create_system_message()

    system_message
  end

  @valid_attrs %{scheduling_date: ~N[2010-04-17 14:00:00], status: :sent}

  @spec sedex_export_fixture(tenant :: Tenant.t(), attrs :: Hygeia.ecto_changeset_params()) ::
          SedexExport.t()
  def sedex_export_fixture(tenant \\ tenant_fixture(), attrs \\ %{}) do
    {:ok, sedex_export} =
      TenantContext.create_sedex_export(tenant, Enum.into(attrs, @valid_attrs))

    sedex_export
  end

  @valid_attrs %{kind: :employee}

  @spec affiliation_fixture(
          person :: Person.t(),
          organisation :: Organisation.t(),
          attrs :: Hygeia.ecto_changeset_params()
        ) :: Affiliation.t()
  def affiliation_fixture(
        person \\ person_fixture(),
        organisation \\ organisation_fixture(),
        attrs \\ %{}
      ) do
    {:ok, affiliation} =
      OrganisationContext.create_affiliation(person, organisation, Enum.into(attrs, @valid_attrs))

    affiliation
  end

  @valid_attrs %{description: "some description", title: "some title"}

  @spec division_fixture(
          organisation :: Organisation.t(),
          attrs :: Hygeia.ecto_changeset_params()
        ) :: Division.t()
  def division_fixture(organisation \\ organisation_fixture(), attrs \\ %{}) do
    {:ok, division} =
      OrganisationContext.create_division(organisation, Enum.into(attrs, @valid_attrs))

    division
  end

  @valid_attrs %{
    body: %{__type__: :case_assignee, case_uuid: "a4f86204-9510-4b69-aef2-f8e78bab5760"},
    notified: true,
    read: true
  }

  @spec notification_fixture(user :: User.t(), attrs :: Hygeia.ecto_changeset_params()) ::
          Notification.t()
  def notification_fixture(user \\ user_fixture(), attrs \\ %{}) do
    {:ok, notification} =
      NotificationContext.create_notification(user, Enum.into(attrs, @valid_attrs))

    notification
  end

  @valid_attrs %{
    start: ~D[2020-01-01],
    end: ~D[2020-01-01]
  }

  @spec hospitalization_fixture(
          case :: Case.t(),
          organisation :: Organisation.t(),
          attrs :: Hygeia.ecto_changeset_params()
        ) ::
          Hospitalization.t()
  def hospitalization_fixture(
        case \\ case_fixture(),
        organisation \\ organisation_fixture(),
        attrs \\ %{}
      ) do
    {:ok, hospitalization} =
      CaseContext.create_hospitalization(
        case,
        @valid_attrs |> Map.merge(%{organisation_uuid: organisation.uuid}) |> Map.merge(attrs)
      )

    hospitalization
  end

  @valid_attrs %{corrected: %{}, identifiers: %{}, data: %{}, status: :pending}

  @spec row_fixture(import :: Import.t(), attrs :: Hygeia.ecto_changeset_params()) :: Row.t()
  def row_fixture(import \\ import_fixture(), attrs \\ %{}) do
    {:ok, row} = ImportContext.create_row(import, Enum.into(attrs, @valid_attrs))

    row
  end

  @valid_attrs %{type: :ism_2021_06_11_test}

  @spec import_fixture(tenant :: Tenant.t(), attrs :: Hygeia.ecto_changeset_params()) ::
          Import.t()
  def import_fixture(tenant \\ tenant_fixture(), attrs \\ %{}) do
    {:ok, import} = ImportContext.create_import(tenant, Enum.into(attrs, @valid_attrs))

    import
  end

  @valid_attrs %{
    tested_at: ~D[2020-10-11],
    laboratory_reported_at: ~D[2020-10-12],
    kind: :pcr,
    result: :positive
  }

  @spec test_fixture(case :: Case.t(), attrs :: Hygeia.ecto_changeset_params()) :: Test.t()
  def test_fixture(case \\ case_fixture(), attrs \\ %{}) do
    {:ok, test} = CaseContext.create_test(case, Enum.into(attrs, @valid_attrs))

    test
  end

  @valid_attrs %{name: "some name", ism_code: 42}

  @spec mutation_fixture(attrs :: Hygeia.ecto_changeset_params()) :: Mutation.t()
  def mutation_fixture(attrs \\ %{}) do
    {:ok, mutation} =
      attrs
      |> Enum.into(@valid_attrs)
      |> MutationContext.create_mutation()

    mutation
  end

  @valid_attrs %{country: "CH"}

  @spec risk_country_fixture(attrs :: Hygeia.ecto_changeset_params()) :: RiskCountry.t()
  def risk_country_fixture(attrs \\ %{}) do
    {:ok, risk_country} =
      attrs
      |> Enum.into(@valid_attrs)
      |> RiskCountryContext.create_risk_country()

    risk_country
  end

  @valid_attrs %{reason: :immune, has_documentation: true, truthful: true}

  @spec premature_release_fixture(case :: Case.t(), attrs :: Hygeia.ecto_changeset_params()) ::
          PrematureRelease.t()
  def premature_release_fixture(case \\ case_fixture(), attrs \\ %{}) do
    {:ok, %PrematureRelease{uuid: uuid}} =
      CaseContext.create_premature_release(
        case,
        List.first(case.phases),
        Enum.into(attrs, @valid_attrs)
      )

    CaseContext.get_premature_release!(uuid)
  end

  @valid_attrs %{current_step: :contact_methods}

  @spec auto_tracing_fixture(case :: Case.t(), attrs :: Hygeia.ecto_changeset_params()) ::
          AutoTracing.t()
  def auto_tracing_fixture(case \\ case_fixture(), attrs \\ %{}) do
    {:ok, auto_tracing} =
      AutoTracingContext.create_auto_tracing(case, Enum.into(attrs, @valid_attrs))

    auto_tracing
  end
end
