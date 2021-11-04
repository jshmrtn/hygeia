defmodule Hygeia.Helpers.Empty do
  @moduledoc false

  import Ecto.Changeset
  import HygeiaGettext

  alias Ecto.Changeset

  @spec is_empty?(changeset :: Changeset.t(), extra_ignore_fields :: [atom()]) :: boolean
  def is_empty?(changeset, extra_ignore_fields \\ []),
    do: drop_recursively(changeset, extra_ignore_fields) == %{}

  defp drop_recursively(%Changeset{changes: changes}, extra_ignore_fields),
    do: drop_recursively(changes, extra_ignore_fields)

  defp drop_recursively(%{} = changes, extra_ignore_fields) when not is_struct(changes) do
    changes
    |> Map.drop([:uuid, :inserted_at, :created_at] ++ extra_ignore_fields)
    |> Enum.map(&{elem(&1, 0), drop_recursively(elem(&1, 1), extra_ignore_fields)})
    |> Enum.reject(&match?({_key, value} when value == %{}, &1))
    |> Map.new()
  end

  defp drop_recursively(changes, _extra_ignore_fields), do: changes

  @spec validate_embed_required(changeset :: Changeset.t(resource), embed :: atom, type :: module) ::
          Changeset.t(resource)
        when resource: term
  def validate_embed_required(changeset, embed, type) do
    changeset
    |> fetch_field!(embed)
    |> case do
      nil ->
        add_error(changeset, embed, dgettext("errors", "is required"))

      other ->
        other
        |> type.changeset(%{}, %{required: true})
        |> case do
          %Ecto.Changeset{valid?: true} ->
            changeset

          %Ecto.Changeset{valid?: false} ->
            add_error(changeset, embed, dgettext("errors", "is invalid"))
        end
    end
  end
end
