defmodule Hygeia.AutoTracingContext.AutoTracingCommunication do
  @moduledoc false

  import HygeiaGettext
  import Cldr.Message.Sigil

  alias Hygeia.CaseContext.Case
  alias Hygeia.TenantContext.Tenant

  @url_generator Application.compile_env!(:hygeia, [__MODULE__, :url_generator])

  @spec auto_tracing_sms(case :: Case.t()) :: String.t()
  def auto_tracing_sms(case),
    do:
      gettext(
        ~M"""
        Dear Sir / Madam,

        You have been recently tested positive for Coronavirus. We would like to ask you to fill out the information on the following link:
        {public_overview_link}

        Please open this link and log in using your first name & last name. (initials: {initial_first_name}. {initial_last_name}.)

        Thanks for your help!

        Kind Regards,
        {message_signature}
        """,
        public_overview_link: @url_generator.overview_url(case),
        message_signature: Tenant.get_message_signature_text(case.tenant, :sms),
        initial_first_name: String.slice(case.person.first_name, 0..0),
        initial_last_name: String.slice(case.person.last_name || "", 0..0)
      )

  @spec auto_tracing_email_subject(case :: Case.t()) :: String.t()
  def auto_tracing_email_subject(case),
    do: gettext(~M"{tenant} - Contact Tracing", tenant: case.tenant.name)

  @spec auto_tracing_email_body(case :: Case.t()) :: String.t()
  def auto_tracing_email_body(case) do
    gettext(
      ~M"""
      Dear Sir / Madam,

      You have been recently tested positive for Coronavirus. To contain the further spread the Contact Tracing relies on your support.

      We would like to ask you to fill out the information on the following link:
      {public_overview_link}

      Please open this link and log in using your first name & last name. (initials: {initial_first_name}. {initial_last_name}.)

      Thanks for your help!

      Kind Regards,
      {message_signature}
      """,
      public_overview_link: @url_generator.overview_url(case),
      message_signature: Tenant.get_message_signature_text(case.tenant, :email),
      initial_first_name: String.slice(case.person.first_name, 0..0),
      initial_last_name: String.slice(case.person.last_name || "", 0..0)
    )
  end
end
