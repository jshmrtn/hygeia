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
      reasons_for_test: "Reasons for test",
      symptoms: "Symptoms",
      symptom_start: "Symptoms start date"
    },
    Hygeia.CaseContext.Hospitalization => %{
      end: "End",
      organisation: "Hospital",
      organisation_uuid: "Hospital UUID",
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
      quarantine_order: "Quarantine / Isolation",
      send_automated_close_email: "Send Automated Close Email",
      start: "Start",
      type: "Type"
    },
    Hygeia.CaseContext.Case.Phase.Index => %{
      end_reason: "End Reason",
      end_reason_date: "End Reason Set Date",
      other_end_reason: "Other End Reason"
    },
    Hygeia.CaseContext.Case.Phase.PossibleIndex => %{
      end_reason: "End Reason",
      end_reason_date: "End Reason Set Date",
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
    Hygeia.CaseContext.Entity => %{
      address: "Address",
      division: "Division",
      name: "Name",
      person_first_name: "Person Firstname",
      person_last_name: "Person Lastname"
    },
    Hygeia.CaseContext.ExternalReference => %{
      type: "Type",
      type_name: "Type name",
      value: "Value"
    },
    Hygeia.CaseContext.Note => %{note: "Note", pinned: "Pinned"},
    Hygeia.CaseContext.Person => %{
      address: "Address",
      birth_date: "Birth Date",
      contact_methods: "Contact Methods",
      employers: "Employers",
      external_references: "References",
      first_name: "First Name",
      last_name: "Last Name",
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
      name: "Name of Vaccine"
    },
    Hygeia.CaseContext.Person.VaccinationShot => %{
      vaccine_type: "Vaccine",
      date: "Date",
      other_vaccine_name: "Name of Vaccine"
    },
    Hygeia.CaseContext.PossibleIndexSubmission => %{
      address: "Address",
      birth_date: "Birth Date",
      case: "Case",
      case_uuid: "Case UUID",
      comment: "Comment",
      email: "Email",
      first_name: "First Name",
      infection_place: "Infection Place",
      landline: "Landline",
      last_name: "Last Name",
      mobile: "Mobile",
      sex: "Sex",
      transmission_date: "Transmission Date",
      employer: "Employer"
    },
    Hygeia.CaseContext.PrematureRelease => %{
      has_documentation: "Has Documentation",
      phase: "Phase",
      reason: "Reason",
      truthful: "Is truthful"
    },
    Hygeia.CaseContext.Test => %{
      result: "Result",
      sponsor: "Sponsor",
      tested_at: "Test date",
      kind: "Test Kind",
      laboratory_reported_at: "Laboratory report date",
      reporting_unit: "Reporting unit",
      mutation: "Mutation",
      reference: "Reference"
    },
    Hygeia.CaseContext.Transmission => %{
      comment: "Comment",
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
      name: "Name of the Place",
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
    Hygeia.ImportContext.Import => %{
      change_date: "Change Date",
      closed_at: "Closed At",
      default_supervisor: "Default Supervisor",
      default_tracer: "Default Tracer",
      file: "File",
      tenant: "Tenant",
      tenant_uuid: "Tenant UUID",
      type: "Type",
      filename: "File Name"
    },
    Hygeia.ImportContext.Row => %{
      identifiers: "Identifiers",
      status: "Status"
    },
    Hygeia.MutationContext.Mutation => %{name: "Name", ism_code: "ISM Code"},
    Hygeia.OrganisationContext.Affiliation => %{
      comment: "Comment",
      division: "Division",
      division_uuid: "Division UUID",
      kind: "Kind",
      kind_other: "Kind Other",
      organisation: "Organisation",
      organisation_uuid: "Organisation UUID",
      person: "Person",
      person_uuid: "Person UUID"
    },
    Hygeia.OrganisationContext.Division => %{
      address: "Address",
      description: "Description",
      organisation: "Organisation",
      organisation_uuid: "Organisation UUID",
      shares_address: "Shares Address",
      title: "Title"
    },
    Hygeia.OrganisationContext.Organisation => %{
      address: "Address",
      name: "Name",
      notes: "Notes",
      school_type: "School Type",
      type: "Type",
      type_other: "Type Other"
    },
    Hygeia.OrganisationContext.Visit => %{
      reason: "Reason",
      other_reason: "Other reason",
      last_visit_at: "Date of last visit",
      organisation: "Organisation",
      unknown_organisation: "Unknown organisation",
      division: "Division",
      unknown_division: "Unknown division"
    },
    Hygeia.RiskCountryContext.RiskCountry => %{
      country: "Country"
    },
    Hygeia.SystemMessageContext.SystemMessage => %{
      text: "Text",
      start_date: "Start Date",
      end_date: "End Date",
      roles: "Roles",
      related_tenants: "Related Tenants"
    },
    Hygeia.TenantContext.SedexExport => %{
      scheduling_date: "Scheduling Date",
      status: "Status",
      tenant: "Tenant",
      tenant_uuid: "Tenant UUID"
    },
    Hygeia.TenantContext.Tenant => %{
      case_management_enabled: "Case Management Enabled",
      contact_email: "Contact Email",
      contact_phone: "Contact Phone",
      country: "Country",
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
      subdivision: "Subdivision",
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
      change_password: "Change Password",
      hostname: "Hostname",
      password: "Password",
      port: "Port",
      server: "Server",
      username: "Username"
    },
    Hygeia.TenantContext.Tenant.Websms => %{access_token: "Access Token"},
    Hygeia.TenantContext.Tenant.TemplateParameters => %{
      sms_signature: "SMS Signature",
      email_signature: "Email Signature"
    },
    Hygeia.UserContext.User => %{
      display_name: "Display Name",
      email: "Email",
      grants: "Grants",
      iam_sub: "IAM Subject",
      roles: "Roles"
    },
    Hygeia.VersionContext.Version => %{
      date: "Date",
      item_changes: "Changes",
      origin: "Origin",
      originator: "Author",
      type: "Type"
    },
    HygeiaWeb.CaseLive.CreatePossibleIndex.FormStep.DefinePeople.Search => %{
      first_name: "Firstname",
      last_name: "Lastname",
      email: "Email",
      landline: "Landline",
      mobile: "Mobile",
      tenant: "Tenant"
    },
    HygeiaWeb.CaseLive.CreatePossibleIndex.FormStep.DefineAdministration => %{
      status: "Status",
      supervisor_uuid: "Supervisor UUID",
      tracer_uuid: "Tracer UUID"
    },
    HygeiaWeb.CaseLive.CreatePossibleIndex.FormStep.DefineTransmission => %{
      type: "Type",
      type_other: "Other",
      comment: "Comment",
      copy_address_from_propagator: "Copy Address From Propagator",
      date: "Date",
      propagator_case: "Propagator Case",
      propagator_case_uuid: "Propagator Case UUID",
      propagator_ism_id: "Propagator ISM ID"
    },
    HygeiaWeb.CaseLive.CreatePossibleIndex.FormStep.Summary => %{
      status: "Status",
      supervisor_uuid: "Supervisor UUID",
      tracer_uuid: "Tracer UUID"
    },
    HygeiaWeb.AutoTracingLive.ContactMethods => %{
      email: "Email",
      landline: "Landline",
      mobile: "Mobile"
    },
    HygeiaWeb.AutoTracingLive.Travel => %{
      has_flown: "Has flown",
      has_travelled: "Has travelled"
    },
    HygeiaWeb.AutoTracingLive.ResolveProblems.LinkPropagatorOpts => %{
      propagator_case: "Propagator Case",
      propagator_ism_id: "Propagator ISM ID"
    },
    Hygeia.AutoTracingContext.AutoTracing => %{
      mobile: "Mobile",
      landline: "Landline",
      email: "Email"
    },
    Hygeia.AutoTracingContext.AutoTracing.Flight => %{
      flight_date: "Flight date",
      departure_place: "Place of departure",
      arrival_place: "Place of arrival",
      flight_number: "Flight number",
      seat_number: "Seat number",
      wore_mask: "Wore mask"
    },
    Hygeia.AutoTracingContext.AutoTracing.Occupation => %{
      kind: "Kind",
      kind_other: "Kind other",
      known_organisation: "Organisation",
      not_found: "Organisation not found",
      division_not_found: "Division not found",
      known_division: "Division"
    },
    Hygeia.AutoTracingContext.AutoTracing.Propagator => %{
      first_name: "First Name",
      last_name: "Last Name",
      phone: "Phone",
      email: "Email",
      address: "Address"
    },
    Hygeia.AutoTracingContext.AutoTracing.OrganisationVisit => %{
      visit_reason: "Reason for your visit",
      other_reason: "Please specify your reason",
      visited_at: "Date of last visit",
      organisation: "Educational institution",
      not_found: "Institution not found",
      division_not_found: "Class or division not found",
      known_division: "Class or division"
    },
    Hygeia.AutoTracingContext.AutoTracing.Travel => %{
      last_departure_date: "Date of last departure",
      country: "Country"
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
