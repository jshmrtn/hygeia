defmodule Hygeia.TenantContext.Tenant.Websms do
  @moduledoc """
  Model for Smtp Outgoing Mail Configuration Schema
  """

  use Hygeia, :model

  import Ecto.Changeset

  @type empty :: %__MODULE__{
          access_token: String.t() | nil
        }

  @type t :: %__MODULE__{
          access_token: String.t()
        }

  @primary_key false
  embedded_schema do
    field :access_token, :string
  end

  @doc false
  @spec changeset(
          websms :: t | empty,
          attrs :: Hygeia.ecto_changeset_params()
        ) :: Changeset.t()
  def changeset(websms, attrs) do
    websms
    |> cast(attrs, [:access_token])
    |> verify_websms_token_existence()
    |> validate_required([:access_token])
  end

  defp verify_websms_token_existence(changeset) do
    changeset
    |> get_change(:access_token)
    |> case do
      token when token in [nil, ""] ->
        delete_change(changeset, :access_token)

      _good_token ->
        changeset
    end
  end

  defimpl Hygeia.SmsSender do
    alias Hygeia.CommunicationContext.SMS
    alias Hygeia.TenantContext.Tenant.Websms, as: WebsmsModel

    @origin_country Application.compile_env!(:hygeia, [:phone_number_parsing_origin_country])

    case Mix.env() do
      :prod -> @test_mode false
      _env -> @test_mode true
    end

    @spec send(config :: WebsmsModel.t(), sms :: SMS.t()) :: {SMS.Status.t(), String.t() | nil}
    def send(%WebsmsModel{access_token: access_token}, %SMS{message: message, number: number}) do
      {:ok, parsed_number} = ExPhoneNumber.parse(number, @origin_country)
      number = ExPhoneNumber.Formatting.format(parsed_number, :e164)

      %{
        body: %{
          messageContent: message,
          test: @test_mode,
          recipientAddressList: [number]
        },
        headers: %{"authorization" => "Bearer #{access_token}"}
      }
      |> Websms.post_smsmessaging_text()
      |> case do
        {:ok, {200, %{statusCode: 2000, transferId: delivery_receipt_id}, _client}} ->
          {:success, delivery_receipt_id}

        {:ok, {200, %{statusMessage: _message}, _client}} ->
          {:failure, nil}
      end
    end
  end
end
