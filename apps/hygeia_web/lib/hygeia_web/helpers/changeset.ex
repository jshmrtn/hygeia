defmodule HygeiaWeb.Helpers.Changeset do
  @moduledoc false

  import HygeiaWeb.ErrorHelpers
  import Phoenix.LiveView

  alias Ecto.Changeset

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
        ) ::
          %{optional(String.t()) => term}
  def changeset_add_to_params(
        %Changeset{params: params} = changeset,
        field,
        new_params \\ %{},
        id_fields \\ [:uuid]
      ) do
    default =
      changeset
      |> Changeset.fetch_field!(field)
      |> Enum.map(&Map.take(&1, id_fields))
      |> Enum.map(fn map ->
        Map.new(map, &{Atom.to_string(elem(&1, 0)), elem(&1, 1)})
      end)

    new_params = Map.new(new_params, &{Atom.to_string(elem(&1, 0)), elem(&1, 1)})

    params
    |> Map.put_new(Atom.to_string(field), default)
    |> Map.update!(
      Atom.to_string(field),
      fn
        list when is_list(list) ->
          list ++ [new_params]

        %{} = map ->
          new_key =
            map
            |> Map.keys()
            |> Enum.map(&String.to_integer/1)
            |> Enum.max(&>=/2, fn -> -1 end)
            |> Kernel.+(1)
            |> Integer.to_string()

          Map.put(map, new_key, new_params)
      end
    )
  end

  @spec changeset_remove_from_params_by_id(
          changeset :: Changeset.t(),
          field :: atom,
          ids :: %{atom => term}
        ) :: %{optional(String.t()) => term}
  def changeset_remove_from_params_by_id(%Changeset{params: params} = changeset, field, ids) do
    default =
      changeset
      |> Changeset.fetch_field!(field)
      |> Enum.map(&Map.take(&1, Map.keys(ids)))
      |> Enum.map(fn map ->
        Map.new(map, &{Atom.to_string(elem(&1, 0)), elem(&1, 1)})
      end)

    string_ids = Map.new(ids, &{Atom.to_string(elem(&1, 0)), elem(&1, 1)})

    params
    |> Map.put_new(Atom.to_string(field), default)
    |> Map.update!(
      Atom.to_string(field),
      fn
        list when is_list(list) ->
          Enum.reject(list, &(Map.take(&1, Map.keys(string_ids)) == string_ids))

        %{} = map ->
          map
          |> Map.values()
          |> Enum.reject(&(Map.take(&1, Map.keys(string_ids)) == string_ids))
          |> Enum.with_index()
          |> Map.new(&{Integer.to_string(elem(&1, 1)), elem(&1, 0)})

        nil ->
          nil
      end
    )
  end
end
