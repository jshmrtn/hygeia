defmodule HygeiaWeb.Helpers.FieldName do
  @moduledoc false

  import HygeiaGettext

  require Logger

  @general_field_names %{
    human_readable_id: "Human Readable ID",
    inserted_at: "Inserted At",
    updated_at: "Updated At",
    uuid: "UUID",
    __type__: "Kind"
  }

  @field_names %{
    Hygeia.CaseContext.Address => %{
      address: "Address",
      country: "Country",
      place: "Place",
      subdivision: "Subdivision",
      zip: "ZIP"
    },
    Hygeia.CaseContext.Case => %{
      clinical: "Clinical Information",
      complexity: "Complexity",
      external_references: "References",
      hospitalizations: "Hospitalizations",
      monitoring: "Monitoring",
      person: "Person",
      person_uuid: "Person UUID",
      phases: "Phases",
      status: "Status",
      supervisor: "Supervisor",
      supervisor_uuid: "Supervisor UUID",
      tenant: "Tenant",
      tenant_uuid: "Tenant UUID",
      tracer: "Tracer",
      tracer_uuid: "Tracer UUID"
    },
    Hygeia.CaseContext.Case.Clinical => %{
      has_symptoms: "Has Symptoms",
      laboratory_report: "Laboratory report date",
      reasons_for_test: "Reasons for test",
      reporting_unit: "Reporting unit",
      result: "Result",
      sponsor: "Sponsor",
      symptoms: "Symptoms",
      test: "Test date",
      test_kind: "Test Kind",
      symptom_start: "Symptoms start date"
    },
    Hygeia.CaseContext.Case.Hospitalization => %{
      end: "End",
      organisation: "Organisation",
      organisation_uuid: "Organisation UUID",
      start: "Start"
    },
    Hygeia.CaseContext.Case.Monitoring => %{
      address: "Address",
      first_contact: "First Contact",
      location: "Location",
      location_details: "Location Details"
    },
    Hygeia.CaseContext.Case.Phase => %{
      automated_close_email_sent: "Automated close email sent",
      details: "Details",
      end: "End",
      send_automated_close_email: "Send Automated Close Email",
      start: "Start",
      type: "Type"
    },
    Hygeia.CaseContext.Case.Phase.Index => %{
      end_reason: "End Reason",
      other_end_reason: "Other End Reason"
    },
    Hygeia.CaseContext.Case.Phase.PossibleIndex => %{
      end_reason: "End Reason",
      type: "Type",
      type_other: "Other Type",
      other_end_reason: "Other End Reason"
    },
    Hygeia.CaseContext.Employer => %{
      address: "Address",
      name: "Name",
      supervisor_name: "Supervisor Name",
      supervisor_phone: "Supervisor Phone"
    },
    Hygeia.CaseContext.Entity => %{address: "Address", name: "Name"},
    Hygeia.CaseContext.ExternalReference => %{
      type: "Type",
      type_name: "Type name",
      value: "Value"
    },
    Hygeia.CaseContext.Note => %{note: "Note"},
    Hygeia.CaseContext.Person => %{
      address: "Address",
      birth_date: "Birth Date",
      contact_methods: "Contact Methods",
      employers: "Employers",
      external_references: "References",
      first_name: "First Name",
      last_name: "Lasr Name",
      profession_category: "Profession",
      profession_category_main: "Profession Category",
      sex: "Sex",
      tenant: "Tenant",
      tenant_uuid: "Tenant UUID",
      vaccination: "Vaccination"
    },
    Hygeia.CaseContext.Person.ContactMethod => %{
      comment: "Comment",
      type: "Typ",
      value: "Value"
    },
    Hygeia.CaseContext.Person.Vaccination => %{
      done: "Done",
      jab_dates: "Jab Dates",
      name: "Name"
    },
    Hygeia.CaseContext.PossibleIndexSubmission => %{
      address: "Address",
      birth_date: "Birth Date",
      case: "Case",
      case_uuid: "Case UUID",
      email: "Email",
      first_name: "First Name",
      infection_place: "Infection Place",
      landline: "Landline",
      last_name: "Last Name",
      mobile: "Mobile",
      sex: "Sex",
      transmission_date: "Transmission Date"
    },
    Hygeia.CaseContext.Transmission => %{
      date: "Date",
      infection_place: "Infection Place",
      propagator_internal: "Propagator Internal",
      propagator: "Propagator",
      propagator_case: "Propagator Case",
      propagator_case_uuid: "Propagator Case UUID",
      propagator_ism_id: "Propagator ISM ID",
      recipient_internal: "Recipient Internal",
      recipient: "Recipient",
      recipient_case: "Recipient Case",
      recipient_case_uuid: "Recipient Case UUID",
      recipient_ism_id: "Recipient ISM ID",
      type: "Type"
    },
    Hygeia.CaseContext.Transmission.InfectionPlace => %{
      address: "Address",
      activity_mapping: "Activity Mapping",
      activity_mapping_executed: "Activity Mapping Executed",
      flight_information: "Flight Information",
      known: "Known",
      name: "Name",
      type: "Type",
      type_other: "Type Other"
    },
    Hygeia.CommunicationContext.Email => %{
      body: "Body",
      subject: "Subject",
      status: "Status",
      recipient: "Recipient",
      to: "To"
    },
    Hygeia.CommunicationContext.SMS => %{number: "Number", message: "Message", status: "Status"},
    Hygeia.OrganisationContext.Organisation => %{
      address: "Address",
      name: "Name",
      notes: "Notes"
    },
    Hygeia.TenantContext.SedexExport => %{
      scheduling_date: "Scheduling Date",
      status: "Status",
      tenant: "Tenant",
      tenant_uuid: "Tenant UUID"
    },
    Hygeia.TenantContext.Tenant => %{
      case_management_enabled: "Case Management Enabled",
      from_email: "From Email",
      iam_domain: "IAM Domain",
      name: "Name",
      outgoing_mail_configuration: "Outgoing Mail Configuration",
      outgoing_mail_configuration_type: "Outgoing Mail Configuration Type",
      outgoing_sms_configuration: "Outgoing SMS Configuration",
      outgoing_sms_configuration_type: "Outgoing SMS Configuration Type",
      override_url: "Override URL",
      public_statistics: "Public Statistics",
      sedex_export_enabled: "Sedex Export Enabled",
      short_name: "Short Name",
      template_variation: "Template Variation"
    },
    Hygeia.TenantContext.Tenant.SedexExportConfiguration => %{
      recipient_id: "Recipient ID",
      recipient_public_key: "Recipient Public Key",
      schedule: "Schedule"
    },
    Hygeia.TenantContext.Tenant.Smtp => %{
      dkim: "DKIM",
      enable_dkim: "Enable DKIM",
      enable_relay: "Enable Relay",
      relay: "Relay"
    },
    Hygeia.TenantContext.Tenant.Smtp.DKIM => %{
      signing_domain_identifier: "Signing Domain Identifier",
      domain: "Domain",
      private_key: "Private Key"
    },
    Hygeia.TenantContext.Tenant.Smtp.Relay => %{
      hostname: "Hostname",
      password: "Password",
      port: "Port",
      server: "Server",
      username: "Username"
    },
    Hygeia.TenantContext.Tenant.Websms => %{access_token: "Access Token"},
    Hygeia.UserContext.User => %{
      display_name: "Display Name",
      email: "Email",
      grants: "Grants",
      iam_sub: "IAM Subject",
      roles: "Roles"
    },
    Hygeia.SystemMessageContext.SystemMessage => %{
      text: "Text",
      start_date: "Start Date",
      end_date: "End Date",
      roles: "Roles",
      related_tenants: "Related Tenants"
    },
    HygeiaWeb.CaseLive.Create.CreatePersonSchema => %{
      address: "Address",
      birth_date: "Birth Date",
      email: "Email",
      employer: "Employer",
      first_name: "First Name",
      ism_case_id: "ISM Case ID",
      ism_report_id: "ISM Report ID",
      landline: "Landline",
      last_name: "Last Name",
      mobile: "Mobile",
      sex: "Sex",
      supervisor: "Supervisor",
      supervisor_uuid: "Supervisor UUID",
      tenant: "Tenant",
      tenant_uuid: "Tenant UUID",
      tracer: "Tracer",
      tracer_uuid: "Tracer UUID"
    },
    HygeiaWeb.CaseLive.CreateIndex.CreateSchema => %{
      default_supervisor: "Default Supervisor",
      default_supervisor_uuid: "Default Supervisor UUID",
      default_tenant: "Default Tenant",
      default_tenant_uuid: "Default Tenant UUID",
      default_tracer: "Default Tracer",
      default_tracer_uuid: "Default Tracer UUID"
    },
    HygeiaWeb.CaseLive.CreatePossibleIndex.CreateSchema => %{
      copy_address_from_propagator: "Copy Address From Propagator",
      date: "Date",
      default_supervisor: "Default Supervisor",
      default_supervisor_uuid: "Default Supervisor UUID",
      default_tenant: "Default Tenant",
      default_tenant_uuid: "Default Tenant UUID",
      default_tracer: "Default Tracer",
      default_tracer_uuid: "Default Tracer UUID",
      directly_close_cases: "Directly Close Cases",
      propagator_case: "Propagator Case",
      propagator_case_uuid: "Propagator Case UUID",
      propagator_ism_id: "Propagator ISM ID",
      send_confirmation_email: "Send Confirmation Email",
      send_confirmation_sms: "Send Confirmation SMS",
      type: "Type",
      type_other: "Other"
    },
    PaperTrail.Version => %{
      date: "Date",
      item_changes: "Changes",
      origin: "Origin",
      originator: "Author",
      type: "Type"
    }
  }

  schema_type =
    @field_names
    |> Enum.map(&elem(&1, 0))
    |> Enum.reduce(&{:|, [], [&1, &2]})

  @type schema :: unquote(schema_type)

  @spec schema_field_name(field :: atom, schema :: schema) :: String.t()

  for {schema, fields} <- @field_names,
      {field, translation} <- fields do
    context = "#{schema} Field"

    def schema_field_name(unquote(field), unquote(schema)),
      do: pgettext(unquote(context), unquote(translation))
  end

  for {field, translation} <- @general_field_names do
    def schema_field_name(unquote(field), _schema),
      do: pgettext("Field", unquote(translation))
  end

  def schema_field_name(field, schema) do
    Logger.warn("Field Name for #{inspect(schema)}/#{field} is not defined")
    field
  end
end
