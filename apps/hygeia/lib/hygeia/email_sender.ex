defprotocol Hygeia.EmailSender do
  @moduledoc """
  Email Sender Protocol
  """

  @spec send(configuration :: t, email :: Hygeia.CommunicationContext.Email.t()) ::
          Hygeia.CommunicationContext.Email.Status.t()
  def send(configuration, email)
end
