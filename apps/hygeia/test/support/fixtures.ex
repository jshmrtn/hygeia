defmodule Hygeia.Fixtures do
  @moduledoc """
  Model Fixtures Helper
  """

  alias Hygeia.CaseContext
  alias Hygeia.CaseContext.Case
  alias Hygeia.CaseContext.InfectionPlaceType
  alias Hygeia.CaseContext.Person
  alias Hygeia.CaseContext.PossibleIndexSubmission
  alias Hygeia.CaseContext.Profession
  alias Hygeia.CaseContext.ProtocolEntry
  alias Hygeia.CaseContext.Transmission
  alias Hygeia.OrganisationContext
  alias Hygeia.OrganisationContext.Organisation
  alias Hygeia.TenantContext
  alias Hygeia.TenantContext.Tenant
  alias Hygeia.UserContext
  alias Hygeia.UserContext.User

  @valid_attrs %{name: "some name"}

  @spec tenant_fixture(attrs :: Hygeia.ecto_changeset_params()) :: Tenant.t()
  def tenant_fixture(attrs \\ %{}) do
    {:ok, tenant} =
      attrs
      |> Enum.into(@valid_attrs)
      |> TenantContext.create_tenant()

    tenant
  end

  @valid_attrs %{name: "some name"}

  @spec profession_fixture(attrs :: Hygeia.ecto_changeset_params()) :: Profession.t()
  def profession_fixture(attrs \\ %{}) do
    {:ok, profession} =
      attrs
      |> Enum.into(@valid_attrs)
      |> CaseContext.create_profession()

    profession
  end

  @valid_attrs %{
    display_name: "Wilfred Walrus",
    email: "wilfred.walrus@example.com",
    iam_sub: "8fe86005-b3c6-4d7c-9746-53e090d05e48"
  }

  @spec user_fixture(attrs :: Hygeia.ecto_changeset_params()) :: User.t()
  def user_fixture(attrs \\ %{}) do
    {:ok, user} =
      attrs
      |> Enum.into(@valid_attrs)
      |> UserContext.create_user()

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

  @valid_attrs %{
    complexity: :medium,
    status: :first_contact,
    hospitalizations: [
      %{start: ~D[2020-10-13], end: ~D[2020-10-15]},
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
    {:ok, case} =
      CaseContext.create_case(
        person,
        attrs
        |> Enum.into(@valid_attrs)
        |> Map.put_new(:tracer_uuid, tracer.uuid)
        |> Map.put_new(:supervisor_uuid, supervisor.uuid)
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
    date: ~D[2010-04-17],
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
  }

  @spec transmission_fixture(attrs :: Hygeia.ecto_changeset_params()) :: Transmission.t()
  def transmission_fixture(attrs \\ %{}) do
    {:ok, transmission} =
      attrs
      |> Enum.into(@valid_attrs)
      |> CaseContext.create_transmission()

    transmission
  end

  @valid_attrs %{position: "some position"}
  @spec position_fixture(
          person :: Person.t(),
          organisation :: Organisation.t(),
          attrs :: Hygeia.ecto_changeset_params()
        ) :: Position.t()
  def position_fixture(
        person \\ person_fixture(),
        organisation \\ organisation_fixture(),
        attrs \\ %{}
      ) do
    {:ok, position} =
      attrs
      |> Enum.into(@valid_attrs)
      |> Map.put_new(:person_uuid, person.uuid)
      |> Map.put_new(:organisation_uuid, organisation.uuid)
      |> OrganisationContext.create_position()

    position
  end

  @valid_attrs %{entry: %{__type__: "note", note: "some note"}}

  @spec protocol_entry_fixture(case :: Cate.t(), attrs :: Hygeia.ecto_changeset_params()) ::
          ProtocolEntry.t()
  def protocol_entry_fixture(case \\ case_fixture(), attrs \\ %{}) do
    {:ok, protocol_entry} =
      CaseContext.create_protocol_entry(case, Enum.into(attrs, @valid_attrs))

    protocol_entry
  end

  @valid_attrs %{name: "some name"}

  @spec infection_place_type_fixture(attrs :: Hygeia.ecto_changeset_params()) ::
          InfectionPlaceType.t()
  def infection_place_type_fixture(attrs \\ %{}) do
    {:ok, infection_place_type} =
      attrs
      |> Enum.into(@valid_attrs)
      |> CaseContext.create_infection_place_type()

    infection_place_type
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
end
