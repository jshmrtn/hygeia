defmodule HygeiaWeb.CaseLive.CreateIndex.CreateSchema do
  @moduledoc false

  use Hygeia, :model

  alias Hygeia.TenantContext.Tenant
  alias Hygeia.UserContext.User
  alias HygeiaWeb.CaseLive.Create.CreatePersonSchema

  embedded_schema do
    belongs_to :default_tenant, Tenant, references: :uuid, foreign_key: :default_tenant_uuid
    belongs_to :default_supervisor, User, references: :uuid, foreign_key: :default_supervisor_uuid
    belongs_to :default_tracer, User, references: :uuid, foreign_key: :default_tracer_uuid
    field :default_country, :string

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
      :default_country
    ])
    |> cast_embed(:people, required: true)
    |> validate_changeset()
  end

  @spec validate_changeset(changeset :: Ecto.Changeset.t()) :: Ecto.Changeset.t()
  def validate_changeset(changeset) do
    changeset
    |> validate_required([:default_tenant_uuid, :default_supervisor_uuid, :default_tracer_uuid])
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
