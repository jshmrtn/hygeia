defmodule Hygeia.EmailSender.MailSender do
  @moduledoc false

  use Bamboo.Mailer, otp_app: :hygeia

  import Bamboo.Email

  alias Hygeia.TenantContext.Tenant

  @spec send(
          recipient_name :: String.t(),
          recipient_email :: String.t(),
          subject :: String.t(),
          body :: String.t(),
          tenant :: Tenant.t()
        ) :: :ok | {:error, reason :: term}
  def send(_recipient_name, recipient_email, subject, body, tenant) do
    deliver_now(
      new_email(
        to: recipient_email,
        from: tenant.outgoing_mail_configuration.from_email,
        subject: subject,
        text_body: body
      ),
      config:
        Map.take(tenant.outgoing_mail_configuration, [:server, :port, :username, :password]),
      response: true
    )

    :ok
  rescue
    error in Bamboo.SMTPAdapter.SMTPError -> {:error, error}
  end
end
