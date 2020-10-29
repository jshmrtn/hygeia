defmodule HygeiaWeb.CaseLive.CreateIndex.CreateSchema do
  @moduledoc false

  use Hygeia, :model

  alias HygeiaWeb.CaseLive.CreateIndex.CreatePersonSchema

  embedded_schema do
    embeds_many :people, CreatePersonSchema, on_replace: :delete
  end

  @spec changeset(schema :: %__MODULE__{}, attrs :: Hygeia.ecto_changeset_params()) ::
          Ecto.Changeset.t()
  def changeset(schema, attrs \\ %{}) do
    schema
    |> cast(attrs, [])
    |> cast_embed(:people, required: true)
    |> validate_changeset()
  end

  @spec validate_changeset(changeset :: Ecto.Changeset.t()) :: Ecto.Changeset.t()
  def validate_changeset(changeset) do
    changeset
    |> validate_required([])
    |> drop_empty_rows()
    |> add_one_person()
  end

  defp drop_empty_rows(changeset) do
    put_embed(
      changeset,
      :people,
      changeset
      |> get_change(:people, [])
      |> Enum.reject(fn %Changeset{changes: changes} ->
        Map.drop(changes, [:uuid]) == %{}
      end)
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
