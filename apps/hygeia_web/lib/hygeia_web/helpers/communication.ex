defmodule HygeiaWeb.Helpers.Communication do
  @moduledoc """
  Communication Helpers
  """

  import HygeiaGettext

  alias Hygeia.CommunicationContext.Email
  alias Hygeia.CommunicationContext.SMS

  @spec email_status(status :: Email.Status.t()) :: String.t()
  def email_status(:in_progress), do: pgettext("Email Status", "In Progress")
  def email_status(:success), do: pgettext("Email Status", "Success")
  def email_status(:temporary_failure), do: pgettext("Email Status", "Temporary Failure")
  def email_status(:permanent_failure), do: pgettext("Email Status", "Permanent Failure")
  def email_status(:retries_exceeded), do: pgettext("Email Status", "Retries Exceeded")

  @spec sms_status(status :: SMS.Status.t()) :: String.t()
  def sms_status(:in_progress), do: pgettext("SMS Status", "In Progress")
  def sms_status(:success), do: pgettext("SMS Status", "Success")
  def sms_status(:failure), do: pgettext("SMS Status", "Failure")

  @spec format_recipient(recipient :: {name :: String.t(), email :: String.t()}) :: String.t()
  def format_recipient({name, email}) when is_binary(name) and is_binary(email),
    do: "#{name} <#{email}>"

  @spec format_recipient(recipient :: String.t()) :: String.t()
  def format_recipient(recipient) when is_binary(recipient), do: recipient

  @spec format_recipients(recipients :: [String.t() | {name :: String.t(), email :: String.t()}]) ::
          [String.t()]
  def format_recipients(recipients) when is_list(recipients),
    do: Enum.map(recipients, &format_recipient/1)
end
