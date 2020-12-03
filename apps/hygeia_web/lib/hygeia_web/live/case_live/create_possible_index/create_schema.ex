defmodule HygeiaWeb.CaseLive.CreatePossibleIndex.CreateSchema do
  @moduledoc false

  use Hygeia, :model

  alias Hygeia.CaseContext.Case
  alias Hygeia.CaseContext.Case.Phase.PossibleIndex.Type
  alias Hygeia.CaseContext.Transmission
  alias Hygeia.CaseContext.Transmission.InfectionPlace
  alias Hygeia.TenantContext.Tenant
  alias Hygeia.UserContext.User
  alias HygeiaWeb.CaseLive.Create.CreatePersonSchema

  embedded_schema do
    belongs_to :default_tenant, Tenant, references: :uuid, foreign_key: :default_tenant_uuid
    belongs_to :default_supervisor, User, references: :uuid, foreign_key: :default_supervisor_uuid
    belongs_to :default_tracer, User, references: :uuid, foreign_key: :default_tracer_uuid

    field :default_country, :string

    field :type, Type

    field :date, :date
    field :propagator_ism_id, :string
    field :propagator_internal, :boolean

    field :send_confirmation_sms, :boolean, default: true
    field :send_confirmation_email, :boolean, default: true
    field :directly_close_cases, :boolean, default: true
    field :copy_address_from_propagator, :boolean, default: false

    belongs_to :propagator_case, Case, references: :uuid, foreign_key: :propagator_case_uuid

    embeds_one :infection_place, InfectionPlace

    embeds_many :people, CreatePersonSchema, on_replace: :delete
  end

  @spec changeset(schema :: %__MODULE__{}, attrs :: Hygeia.ecto_changeset_params()) ::
          Ecto.Changeset.t()
  def changeset(schema, attrs \\ %{}) do
    schema
    |> cast(attrs, [
      :default_tenant_uuid,
      :default_supervisor_uuid,
      :default_tracer_uuid,
      :default_country,
      :type,
      :date,
      :propagator_case_uuid,
      :propagator_internal,
      :propagator_ism_id,
      :send_confirmation_sms,
      :send_confirmation_email,
      :directly_close_cases,
      :copy_address_from_propagator
    ])
    |> cast_embed(:people, required: true)
    |> cast_embed(:infection_place, required: true)
    |> validate_changeset()
  end

  @spec validate_changeset(changeset :: Ecto.Changeset.t()) :: Ecto.Changeset.t()
  def validate_changeset(changeset) do
    changeset
    |> validate_required([
      :default_tenant_uuid,
      :default_supervisor_uuid,
      :default_tracer_uuid,
      :type,
      :date
    ])
    |> Transmission.validate_case(:propagator_internal, :propagator_ism_id, :propagator_case_uuid)
    |> drop_empty_rows()
    |> CreatePersonSchema.detect_duplicates()
    |> add_one_person()
  end

  defp drop_empty_rows(changeset) do
    put_embed(
      changeset,
      :people,
      changeset
      |> get_change(:people, [])
      |> Enum.reject(&is_empty?/1)
    )
  end

  defp add_one_person(changeset) do
    put_embed(
      changeset,
      :people,
      get_change(changeset, :people, []) ++
        [CreatePersonSchema.changeset(%CreatePersonSchema{}, %{})]
    )
  end
end
