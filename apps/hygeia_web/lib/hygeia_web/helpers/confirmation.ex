defmodule HygeiaWeb.Helpers.Confirmation do
  @moduledoc false

  import HygeiaGettext

  alias Hygeia.CaseContext.Case
  alias Hygeia.CaseContext.Case.Phase
  alias Hygeia.Repo
  alias Hygeia.TenantContext
  alias Hygeia.TenantContext.Tenant
  alias HygeiaWeb.Router.Helpers, as: Routes

  @spec isolation_sms(
          conn_or_socket :: Plug.Conn.t() | Phoenix.LiveView.Socket.t(),
          case :: Case.t(),
          phase :: Phase.t()
        ) :: String.t()
  def isolation_sms(conn_or_socket, case, phase),
    do: isolation_email_body(conn_or_socket, case, phase, :sms)

  @spec isolation_email_subject() :: String.t()
  def isolation_email_subject, do: gettext("Isolation Order")

  @spec isolation_email_body(
          conn_or_socket :: Plug.Conn.t() | Phoenix.LiveView.Socket.t(),
          case :: Case.t(),
          phase :: Phase.t(),
          message_type :: atom
        ) :: String.t()
  def isolation_email_body(conn_or_socket, case, phase, message_type) do
    case = Repo.preload(case, :tenant)

    gettext(
      """
      Dear Sir / Madam,

      As discussed via phone, you can access the information about your quarantine via the following link:
      %{isolation_confirmation_link}

      To access the confirmation, please log in using you firstname & lastname. (%{initial_first_name}. %{initial_last_name}.)

      Please read the document carefully and consider the links for more information.

      To ensure the contact tracing we need to record personal details of your contacts.
      You can enter persons you had contact with here:
      %{possible_index_submission_link}

      Kind Regards,
      %{message_signature}
      """,
      isolation_confirmation_link:
        TenantContext.replace_base_url(
          case.tenant,
          Routes.pdf_url(conn_or_socket, :isolation_confirmation, case, phase),
          HygeiaWeb.Endpoint.url()
        ),
      possible_index_submission_link:
        TenantContext.replace_base_url(
          case.tenant,
          Routes.possible_index_submission_index_url(conn_or_socket, :index, case),
          HygeiaWeb.Endpoint.url()
        ),
      message_signature: Tenant.get_message_signature_text(case.tenant, message_type),
      initial_first_name: String.slice(case.person.first_name, 0..0),
      initial_last_name: String.slice(case.person.last_name, 0..0)
    )
  end

  @spec quarantine_sms(
          conn_or_socket :: Plug.Conn.t() | Phoenix.LiveView.Socket.t(),
          case :: Case.t(),
          phase :: Phase.t()
        ) :: String.t()
  def quarantine_sms(conn_or_socket, case, phase),
    do: quarantine_email_body(conn_or_socket, case, phase, :sms)

  @spec quarantine_email_subject() :: String.t()
  def quarantine_email_subject, do: gettext("Quarantine Order")

  @spec quarantine_email_body(
          conn_or_socket :: Plug.Conn.t() | Phoenix.LiveView.Socket.t(),
          case :: Case.t(),
          phase :: Phase.t(),
          message_type :: atom
        ) :: String.t()
  def quarantine_email_body(conn_or_socket, case, phase, message_type) do
    case = Repo.preload(case, :tenant)

    gettext(
      """
      Dear Sir / Madam,

      You have been identified as a contact person of a person with corona. For this reason you will have to quanrantine for 10 days. Please consider the instructions and information via the following link:
      %{quarantine_confirmation_link}

      To access the confirmation, please log in using you firstname & lastname. (%{initial_first_name}. %{initial_last_name}.)

      Kind Regards,
      %{message_signature}
      """,
      quarantine_confirmation_link:
        TenantContext.replace_base_url(
          case.tenant,
          Routes.pdf_url(conn_or_socket, :quarantine_confirmation, case, phase),
          HygeiaWeb.Endpoint.url()
        ),
      message_signature: Tenant.get_message_signature_text(case.tenant, message_type),
      initial_first_name: String.slice(case.person.first_name, 0..0),
      initial_last_name: String.slice(case.person.last_name, 0..0)
    )
  end
end
