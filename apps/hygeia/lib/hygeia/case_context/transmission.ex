defmodule Hygeia.CaseContext.Transmission do
  @moduledoc """
  Case Transmission Schema

  A transmission has to point to at least a propagator or a recipient case

  If one of the two sides is managed by an entity outside of this system, an IMS id can be specified instead.
  """

  use Hygeia, :model

  alias Hygeia.CaseContext.Case

  @type t :: %__MODULE__{
          date: Date.t() | nil,
          propagator_internal: boolean,
          propagator_ims_id: String.t() | nil,
          propagator_case: Ecto.Schema.belongs_to(Case.t()) | nil,
          propagator_case_uuid: String.t() | nil,
          recipient_internal: boolean,
          recipient_ims_id: String.t() | nil,
          recipient_case: Ecto.Schema.belongs_to(Case.t()) | nil,
          recipient_case_uuid: String.t() | nil
        }

  @type empty :: %__MODULE__{
          date: Date.t() | nil,
          propagator_internal: boolean | nil,
          propagator_ims_id: String.t() | nil,
          propagator_case: Ecto.Schema.belongs_to(Case.t()) | nil,
          propagator_case_uuid: String.t() | nil,
          recipient_internal: boolean | nil,
          recipient_ims_id: String.t() | nil,
          recipient_case: Ecto.Schema.belongs_to(Case.t()) | nil,
          recipient_case_uuid: String.t() | nil
        }

  @derive {Phoenix.Param, key: :uuid}

  schema "transmissions" do
    field :date, :date
    field :propagator_ims_id, :string
    field :propagator_internal, :boolean
    field :recipient_ims_id, :string
    field :recipient_internal, :boolean

    belongs_to :propagator_case, Case, references: :uuid, foreign_key: :propagator_case_uuid
    belongs_to :recipient_case, Case, references: :uuid, foreign_key: :recipient_case_uuid

    timestamps()
  end

  @spec changeset(transmission :: t | empty, attrs :: Hygeia.ecto_changeset_params()) ::
          Ecto.Changeset.t()
  def changeset(transmission, attrs) do
    transmission
    |> cast(attrs, [
      :date,
      :recipient_internal,
      :recipient_ims_id,
      :propagator_case_uuid,
      :propagator_internal,
      :propagator_ims_id,
      :recipient_case_uuid
    ])
    |> validate_required([])
    |> validate_case(:propagator_internal, :propagator_ims_id, :propagator_case_uuid)
    |> validate_case(:recipient_internal, :recipient_ims_id, :recipient_case_uuid)
    |> validate_propagator_or_recipient_required
  end

  defp validate_case(changeset, internal_key, ims_id_key, case_relation_key) do
    changeset
    |> fetch_field!(internal_key)
    |> case do
      nil ->
        changeset
        |> validate_inclusion(ims_id_key, [nil])
        |> validate_inclusion(case_relation_key, [nil])

      true ->
        changeset
        |> validate_inclusion(ims_id_key, [nil])
        |> validate_required([case_relation_key])

      false ->
        changeset
        |> validate_required([ims_id_key])
        |> validate_inclusion(case_relation_key, [nil])
    end
  end

  defp validate_propagator_or_recipient_required(changeset) do
    changeset
    |> get_field(:propagator_case_uuid)
    |> case do
      nil -> validate_required(changeset, [:recipient_case_uuid])
      uuid when is_binary(uuid) -> validate_required(changeset, [:propagator_case_uuid])
    end
  end
end
