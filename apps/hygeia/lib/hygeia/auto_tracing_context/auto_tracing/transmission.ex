defmodule Hygeia.AutoTracingContext.AutoTracing.Transmission do
  @moduledoc """
  Transmission Model
  """
  use Hygeia, :model

  import HygeiaGettext

  alias Hygeia.CaseContext.Address
  alias Hygeia.CaseContext.Transmission
  alias Hygeia.CaseContext.Transmission.InfectionPlace

  @type t :: %__MODULE__{
          known: boolean,
          propagator_known: boolean | nil,
          propagator_first_name: String.t() | nil,
          propagator_last_name: String.t() | nil,
          propagator_address: Address.t() | nil,
          propagator_phone: String.t() | nil,
          propagator_email: String.t() | nil,
          transmission: Transmission.t() | nil
        }

  @type empty :: %__MODULE__{
          known: boolean | nil,
          propagator_known: boolean | nil,
          propagator_first_name: String.t() | nil,
          propagator_last_name: String.t() | nil,
          propagator_address: Address.t() | nil,
          propagator_phone: String.t() | nil,
          propagator_email: String.t() | nil,
          transmission: Transmission.t() | nil
        }

  embedded_schema do
    field :known, :boolean
    field :propagator_known, :boolean
    field :propagator_first_name, :string
    field :propagator_last_name, :string
    field :propagator_phone, :string
    field :propagator_email, :string
    embeds_one :propagator_address, Address, on_replace: :update

    belongs_to :transmission, Transmission,
      foreign_key: :known_organisation_uuid,
      references: :uuid
  end

  @spec changeset(transmission :: t | empty, attrs :: Hygeia.ecto_changeset_params()) ::
          Ecto.Changeset.t(t)
  def changeset(transmission, attrs) do
    transmission
    |> cast(attrs, [
      :date,
      :known,
      :propagator_known,
      :propagator_first_name,
      :propagator_last_name,
      :propagator_phone,
      :propagator_email
    ])
    |> validate_required([:known])
    |> validate_and_normalize_phone(:propagator_phone, fn
      :mobile -> :ok
      :fixed_line -> :ok
      :fixed_line_or_mobile -> :ok
      :voip -> :ok
      :personal_number -> :ok
      :uan -> :ok
      :unknown -> :ok
      _other -> {:error, "not a phone number"}
    end)
    |> validate_email(:propagator_email)
    |> cast_embed(:infection_place)
    |> cast_embed(:propagator_address)
    |> validate_person_required()
  end

  defp validate_person_required(changeset) do
    changeset
    |> fetch_field!(:propagator_known)
    |> case do
      nil ->
        changeset

      false ->
        changeset

      true ->
        changeset
        |> validate_required([:propagator_first_name, :propagator_last_name])
        |> validate_propagator_contact_method_required()
    end
  end

  defp validate_propagator_contact_method_required(changeset) do
    case {fetch_field!(changeset, :propagator_phone), fetch_field!(changeset, :propagator_email)} do
      {nil, nil} ->
        validate_required(changeset, [:propagator_phone],
          message: dgettext("errors", "at least one contact method must be provided")
        )

      _other ->
        changeset
    end
  end
end
