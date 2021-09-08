defmodule Hygeia.AutoTracingContext.AutoTracing.Propagator do
  @moduledoc """
  Transmission Model
  """
  use Hygeia, :model

  import HygeiaGettext

  alias Hygeia.CaseContext.Address

  @type t :: %__MODULE__{
          first_name: String.t() | nil,
          last_name: String.t() | nil,
          address: Address.t() | nil,
          phone: String.t() | nil,
          email: String.t() | nil
        }

  @type empty :: %__MODULE__{
          first_name: String.t() | nil,
          last_name: String.t() | nil,
          address: Address.t() | nil,
          phone: String.t() | nil,
          email: String.t() | nil
        }

  embedded_schema do
    field :first_name, :string
    field :last_name, :string
    field :phone, :string
    field :email, :string
    embeds_one :address, Address, on_replace: :update
  end

  @spec changeset(transmission :: t | empty, attrs :: Hygeia.ecto_changeset_params()) ::
          Ecto.Changeset.t(t)
  def changeset(transmission, attrs) do
    transmission
    |> cast(attrs, [
      :first_name,
      :last_name,
      :phone,
      :email
    ])
    |> validate_and_normalize_phone(:phone, fn
      :mobile -> :ok
      :fixed_line -> :ok
      :fixed_line_or_mobile -> :ok
      :voip -> :ok
      :personal_number -> :ok
      :uan -> :ok
      :unknown -> :ok
      _other -> {:error, "not a phone number"}
    end)
    |> validate_email(:email)
    |> cast_embed(:address)
    |> validate_propagator_contact_method_required()
  end

  defp validate_propagator_contact_method_required(changeset) do
    case {fetch_field!(changeset, :phone), fetch_field!(changeset, :email)} do
      {nil, nil} ->
        validate_required(changeset, [:phone],
          message: dgettext("errors", "at least one contact method must be provided")
        )

      _other ->
        changeset
    end
  end
end
