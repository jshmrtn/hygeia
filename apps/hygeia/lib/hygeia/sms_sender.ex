defmodule Hygeia.SmsSender do
  @moduledoc """
  SMS Sender Behaviour
  """

  @callback send(
              message_id :: String.t(),
              number :: String.t(),
              text :: String.t(),
              access_token :: String.t()
            ) ::
              {:ok, delivery_receipt_id :: String.t()} | {:error, reason :: term}
end
