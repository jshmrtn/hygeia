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
  def isolation_email_body(conn_or_socket, case, _phase, message_type) do
    case = Repo.preload(case, :tenant)

    gettext(
      """
      Dear Sir / Madam,

      As discussed via phone, you can access the information about your isolation via the following link:
      %{public_overview_link}

      Please open this link and log in using you first name & last name. (initials: %{initial_first_name}. %{initial_last_name}.)

      You will be able download your isolation confirmation and submit people that you were in contact with. You will also be able to download an end-confirmation of your isolation at the end.

      Please read the information about your isolation in your confirmation document and the mentioned links and contact methods.

      Kind Regards,
      %{message_signature}
      """,
      public_overview_link: public_overview_link(conn_or_socket, case),
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
  def quarantine_email_body(conn_or_socket, case, _phase, message_type) do
    case = Repo.preload(case, :tenant)

    gettext(
      """
      Dear Sir / Madam,

      You have been identified as a contact person of a person with corona. For this reason you will have to quarantine for %{quarantine_length}.

      Please open the following link and log in using your first name & last name. (initials: %{initial_first_name}. %{initial_last_name}.)
      %{public_overview_link}

      You will be able to download your quarantine confirmation and possibly shorten / lift your quarantine.

      Please read the information about your quarantine in your confirmation document and the mentioned links and contact methods.

      Kind Regards,
      %{message_signature}
      """,
      quarantine_length:
        :day
        |> Cldr.Unit.new!(Phase.PossibleIndex.default_length_days() + 1)
        |> HygeiaCldr.Unit.to_string!(),
      public_overview_link: public_overview_link(conn_or_socket, case),
      message_signature: Tenant.get_message_signature_text(case.tenant, message_type),
      initial_first_name: String.slice(case.person.first_name, 0..0),
      initial_last_name: String.slice(case.person.last_name, 0..0)
    )
  end

  defp public_overview_link(conn_or_socket, case),
    do:
      TenantContext.replace_base_url(
        case.tenant,
        Routes.person_overview_index_url(conn_or_socket, :index, case.person_uuid),
        HygeiaWeb.Endpoint.url()
      )
end
