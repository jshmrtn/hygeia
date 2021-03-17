defmodule Hygeia.Helpers.Versioning do
  @moduledoc false

  alias Ecto.Multi
  alias Hygeia.Repo
  alias Hygeia.UserContext.User
  alias Hygeia.VersionContext.Version

  @type originator :: User.t() | :noone

  @spec versioning_extract(term) :: term
  def versioning_extract(result), do: result

  @spec versioning_insert(changeset :: Ecto.Changeset.t(resource)) ::
          {:ok, %{model: resource, version: %Version{}}}
          | {:error, Ecto.Changeset.t(resource)}
        when resource: term
  def versioning_insert(changeset) do
    run_ecto_multi(&Multi.insert(&1, &2, changeset))
  end

  @spec versioning_update(changeset :: Ecto.Changeset.t(resource)) ::
          {:ok, %{model: resource, version: %Version{}}}
          | {:error, Ecto.Changeset.t(resource)}
        when resource: term
  def versioning_update(changeset) do
    run_ecto_multi(&Multi.update(&1, &2, changeset))
  end

  @spec versioning_delete(changeset :: Ecto.Changeset.t(resource)) ::
          {:ok, %{model: resource, version: %Version{}}}
          | {:error, Ecto.Changeset.t(resource)}
        when resource: term
  def versioning_delete(changeset) do
    run_ecto_multi(&Multi.delete(&1, &2, changeset))
  end

  @spec put_origin(origin :: Version.Origin.t()) :: :ok
  def put_origin(origin) do
    Process.put({__MODULE__, :origin}, origin)
    :ok
  end

  @spec put_originator(originator :: originator) :: :ok
  def put_originator(originator) when is_struct(originator, User) or originator == :noone do
    Process.put({__MODULE__, :originator}, originator)
    :ok
  end

  @spec authenticate_multi(multi :: Multi.t(), options :: Keyword.t()) :: Multi.t()
  def authenticate_multi(%Multi{} = multi, options \\ []) do
    origin =
      case Keyword.get(options, :origin, get_origin()) do
        nil -> raise "Origin must be set to mutate resources"
        origin when is_atom(origin) -> Atom.to_string(origin)
      end

    originator_id =
      case Keyword.get(options, :originator, get_originator()) do
        nil -> raise "Originator must be set to mutate resources"
        :noone -> nil
        %User{uuid: originator_uuid} -> originator_uuid
      end

    Multi.new()
    |> Multi.run(:set_versioning_variables, fn repo, _changes ->
      repo.query!("SET SESSION versioning.originator_id = '#{originator_id}'")
      repo.query!("SET SESSION versioning.origin = '#{origin}'")
      {:ok, nil}
    end)
    |> Multi.append(multi)
  end

  defp run_ecto_multi(callback, options \\ []) when is_function(callback, 2) do
    Multi.new()
    |> callback.(:resource)
    |> authenticate_multi(options)
    |> Repo.transaction()
    |> case do
      {:ok, %{resource: resource}} -> {:ok, resource}
      {:error, :resource, changeset, _before_results} -> {:error, changeset}
    end
  end

  @spec get_origin(pid :: pid()) :: Version.Origin.t() | nil
  defp get_origin(pid \\ self()), do: get_recursively([pid], {__MODULE__, :origin})

  @spec get_originator(pid :: pid()) :: originator | nil
  defp get_originator(pid \\ self()), do: get_recursively([pid], {__MODULE__, :originator})

  defp get_recursively(pids, key)

  defp get_recursively([], _key), do: nil

  defp get_recursively(pids, key) do
    dictionarys =
      pids
      |> Enum.map(&Process.info(&1, :dictionary))
      |> Enum.map(&elem(&1, 1))
      |> Enum.map(&Map.new/1)

    Enum.find_value(dictionarys, fn
      %{^key => value} -> value
      _other -> false
    end) ||
      dictionarys
      |> Enum.flat_map(&Map.get(&1, :"$ancestors", []))
      |> Enum.map(fn
        pid when is_pid(pid) -> pid
        atom when is_atom(atom) -> Process.whereis(atom)
      end)
      |> get_recursively(key)
  end
end
