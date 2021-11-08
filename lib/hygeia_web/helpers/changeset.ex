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
    new_params = Map.new(new_params, &{key_to_string(elem(&1, 0)), elem(&1, 1)})

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
    string_ids = Map.new(ids, &{key_to_string(elem(&1, 0)), elem(&1, 1)})

    update_changeset_param_relation(
      changeset,
      field,
      Map.keys(ids),
      fn list ->
        Enum.reject(
          list,
          &(Map.take(&1, Map.keys(string_ids)) == string_ids or Map.take(&1, Map.keys(ids)) == ids)
        )
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
    string_ids = Map.new(ids, &{key_to_string(elem(&1, 0)), elem(&1, 1)})

    update_changeset_param_relation(
      changeset,
      field,
      Map.keys(ids),
      &Enum.map(&1, fn entry ->
        if Map.take(entry, Map.keys(string_ids)) == string_ids or
             Map.take(entry, Map.keys(ids)) == ids do
          update_fn.(entry)
        else
          entry
        end
      end)
    )
  end

  @spec update_changeset_param(
          changeset :: Ecto.Changeset.t(),
          field :: atom,
          callback :: (term -> term),
          default_map :: (term -> term)
        ) :: %{optional(String.t()) => term}
  def update_changeset_param(
        %Changeset{params: params} = changeset,
        field,
        callback,
        default_map \\ & &1
      )
      when is_atom(field) and is_function(callback, 1) do
    params
    |> Map.put_new_lazy(key_to_string(field), fn ->
      default = Changeset.fetch_field!(changeset, field)
      default_map.(default)
    end)
    |> Map.update!(key_to_string(field), callback)
  end

  @spec update_changeset_param_relation(
          changeset :: Changeset.t(),
          field :: atom,
          id_fields :: [atom],
          callback :: (term -> term)
        ) :: %{optional(String.t()) => term}
  def update_changeset_param_relation(changeset, field, id_fields, callback) do
    update_changeset_param(
      changeset,
      field,
      fn
        nil ->
          nil

        list when is_list(list) ->
          callback.(list)

        %{} = map ->
          map
          |> Enum.to_list()
          |> Enum.sort_by(&String.to_integer(elem(&1, 0)))
          |> Enum.map(&elem(&1, 1))
          |> callback.()
          |> Enum.with_index()
          |> Map.new(&{Integer.to_string(elem(&1, 1)), elem(&1, 0)})
      end,
      fn default ->
        default
        |> Enum.map(&Map.take(&1, id_fields))
        |> Enum.map(fn map ->
          Map.new(map, &{key_to_string(elem(&1, 0)), elem(&1, 1)})
        end)
      end
    )
  end

  @spec existing_entity?(changeset :: Changeset.t()) :: boolean
  def existing_entity?(%Changeset{data: entity} = _changeset),
    do: Ecto.get_meta(entity, :state) == :loaded

  defp key_to_string(key) when is_atom(key), do: Atom.to_string(key)
  defp key_to_string(key) when is_binary(key), do: key
end
