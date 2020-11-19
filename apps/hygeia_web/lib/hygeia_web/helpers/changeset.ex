defmodule HygeiaWeb.Helpers.Changeset do
  @moduledoc false

  import HygeiaWeb.ErrorHelpers
  import Phoenix.LiveView

  alias Ecto.Changeset

  @type params :: %{optional(String.t()) => term}

  @spec changeset_error_flash(
          socket :: Phoenix.LiveView.Socket.t(),
          changeset :: Changeset.t()
        ) :: Phoenix.LiveView.Socket.t()
  def changeset_error_flash(socket, changeset) do
    changeset
    |> Changeset.traverse_errors(&translate_error/1)
    |> Enum.flat_map(fn {field, errors} ->
      Enum.map(errors, &{field, &1})
    end)
    |> Enum.reduce(socket, fn {field, error}, socket ->
      put_flash(socket, :error, "#{field}: #{error}")
    end)
  end

  @spec changeset_add_to_params(
          changeset :: Changeset.t(),
          field :: atom,
          params :: map,
          id_fields :: [atom]
        ) :: params
  def changeset_add_to_params(changeset, field, new_params \\ %{}, id_fields \\ [:uuid]) do
    new_params = Map.new(new_params, &{Atom.to_string(elem(&1, 0)), elem(&1, 1)})

    update_changeset_param_relation(
      changeset,
      field,
      id_fields,
      fn list ->
        list ++ [new_params]
      end
    )
  end

  @spec changeset_remove_from_params_by_id(
          changeset :: Changeset.t(),
          field :: atom,
          ids :: %{atom => term}
        ) :: params
  def changeset_remove_from_params_by_id(changeset, field, ids) do
    string_ids = Map.new(ids, &{Atom.to_string(elem(&1, 0)), elem(&1, 1)})

    update_changeset_param_relation(
      changeset,
      field,
      Map.keys(ids),
      fn list ->
        Enum.reject(list, &(Map.take(&1, Map.keys(string_ids)) == string_ids))
      end
    )
  end

  @spec changeset_update_params_by_id(
          changeset :: Changeset.t(),
          field :: atom,
          ids :: %{atom => term},
          update_fn :: (params -> params)
        ) :: params
  def changeset_update_params_by_id(changeset, field, ids, update_fn) do
    string_ids = Map.new(ids, &{Atom.to_string(elem(&1, 0)), elem(&1, 1)})

    update_changeset_param_relation(
      changeset,
      field,
      Map.keys(ids),
      &Enum.map(&1, fn entry ->
        if Map.take(entry, Map.keys(string_ids)) == string_ids do
          update_fn.(entry)
        else
          entry
        end
      end)
    )
  end

  defp update_changeset_param_relation(
         %Changeset{params: params} = changeset,
         field,
         id_fields,
         callback
       ) do
    default =
      changeset
      |> Changeset.fetch_field!(field)
      |> Enum.map(&Map.take(&1, id_fields))
      |> Enum.map(fn map ->
        Map.new(map, &{Atom.to_string(elem(&1, 0)), elem(&1, 1)})
      end)

    params
    |> Map.put_new(Atom.to_string(field), default)
    |> Map.update!(
      Atom.to_string(field),
      fn
        list when is_list(list) ->
          callback.(list)

        %{} = map ->
          map
          |> Map.values()
          |> callback.()
          |> Enum.with_index()
          |> Map.new(&{Integer.to_string(elem(&1, 1)), elem(&1, 0)})

        nil ->
          nil
      end
    )
  end
end
