defmodule HygeiaWeb.Helpers.Preload do
  @moduledoc false

  @spec preload_assigns_one(
          assigns_list :: [%{optional(atom()) => term()}],
          name :: atom,
          callback :: (term -> term),
          id_fetcher_callback :: (term -> term),
          ignore_callback :: (term -> boolean)
        ) :: [%{optional(atom()) => term()}]
  def preload_assigns_one(
        assigns_list,
        name,
        callback \\ & &1,
        id_fetcher_callback \\ & &1.uuid,
        ignore_callback \\ &is_nil/1
      )
      when is_list(assigns_list) and is_atom(name) and is_function(callback, 1) and
             is_function(id_fetcher_callback, 1) and is_function(ignore_callback, 1) do
    preloaded_resources =
      assigns_list
      |> Enum.map(& &1[name])
      |> Enum.reject(ignore_callback)
      |> Enum.uniq_by(&id_fetcher_callback.(&1))
      |> callback.()
      |> Map.new(&{id_fetcher_callback.(&1), &1})

    Enum.map(assigns_list, fn
      %{^name => resource} = assigns ->
        if ignore_callback.(resource) do
          assigns
        else
          Map.put(assigns, name, Map.fetch!(preloaded_resources, id_fetcher_callback.(resource)))
        end

      other ->
        other
    end)
  end

  @spec preload_assigns_many(
          assigns_list :: [%{optional(atom()) => term()}],
          name :: atom,
          callback :: (term -> term),
          id_fetcher_callback :: (term -> term),
          ignore_callback :: (term -> boolean)
        ) :: [%{optional(atom()) => term()}]
  def preload_assigns_many(
        assigns_list,
        name,
        callback \\ & &1,
        id_fetcher_callback \\ & &1.uuid,
        ignore_callback \\ &is_nil/1
      )
      when is_list(assigns_list) and is_atom(name) and is_function(callback, 1) and
             is_function(id_fetcher_callback, 1) and is_function(ignore_callback, 1) do
    preloaded_resources =
      assigns_list
      |> Enum.flat_map(& &1[name])
      |> Enum.reject(ignore_callback)
      |> Enum.uniq_by(&id_fetcher_callback.(&1))
      |> callback.()
      |> Map.new(&{id_fetcher_callback.(&1), &1})

    Enum.map(assigns_list, fn
      %{^name => resources} = assigns ->
        Map.put(
          assigns,
          name,
          Enum.map(
            resources,
            &if(ignore_callback.(&1),
              do: &1,
              else: Map.fetch!(preloaded_resources, id_fetcher_callback.(&1))
            )
          )
        )

      other ->
        other
    end)
  end
end
