defprotocol Hygeia.SmsSender do
  @moduledoc """
  SMS Sender Protocol
  """

  @spec send(configuration :: t, sms :: Hygeia.CommunicationContext.SMS.t()) ::
          {status :: Hygeia.CommunicationContext.SMS.Status.t(),
           delivery_receipt_id :: String.t() | nil}
  def send(configuration, sms)
end
