defmodule Hygeia.SmsSender.WebSms do
  @moduledoc """
  `Hygeia.SmsSender` implementation for websms.ch
  """

  @behaviour Hygeia.SmsSender

  case Mix.env() do
    :test -> @test_mode true
    _env -> @test_mode false
  end

  @impl Hygeia.SmsSender
  def send(_message_id, number, text, access_token) do
    %{
      body: %{
        messageContent: text,
        test: @test_mode,
        recipientAddressList: [number]
      },
      headers: %{"authorization" => "Bearer #{access_token}"}
    }
    |> Websms.post_smsmessaging_text()
    |> case do
      {:ok, {200, %{statusCode: 2000, transferId: delivery_receipt_id}, _client}} ->
        {:ok, delivery_receipt_id}

      {:ok, {200, %{statusMessage: message}, _client}} ->
        {:error, message}

      {:ok, {401, _response, _client}} ->
        {:error, :unauthorized}

      {:error, reason} ->
        {:error, reason}
    end
  end
end
