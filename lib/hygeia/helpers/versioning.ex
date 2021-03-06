defmodule Hygeia.Helpers.Versioning do
  @moduledoc false

  alias Ecto.Multi
  alias Hygeia.Helpers.RecursiveProcessDirectory
  alias Hygeia.Repo
  alias Hygeia.UserContext.User
  alias Hygeia.VersionContext.Version

  @type originator :: User.t() | :noone

  @spec versioning_extract(term) :: term
  def versioning_extract(result), do: result

  @spec versioning_insert(changeset :: Ecto.Changeset.t(resource)) ::
          {:ok, %{model: resource, version: Version.t()}}
          | {:error, Ecto.Changeset.t(resource)}
        when resource: term
  def versioning_insert(changeset) do
    run_ecto_multi(&Multi.insert(&1, &2, changeset))
  end

  @spec versioning_update(changeset :: Ecto.Changeset.t(resource)) ::
          {:ok, %{model: resource, version: Version.t()}}
          | {:error, Ecto.Changeset.t(resource)}
        when resource: term
  def versioning_update(changeset) do
    run_ecto_multi(&Multi.update(&1, &2, changeset))
  end

  @spec versioning_delete(changeset_or_resource :: Ecto.Changeset.t(resource) | resource) ::
          {:ok, %{model: resource, version: Version.t()}}
          | {:error, Ecto.Changeset.t(resource)}
        when resource: Ecto.Schema.t()
  def versioning_delete(changeset_or_resource) do
    run_ecto_multi(&Multi.delete(&1, &2, changeset_or_resource))
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

  @spec run_authentication(repo :: atom, options :: Keyword.t()) :: :ok
  def run_authentication(repo, options) do
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

    repo.query!("SELECT SET_CONFIG('versioning.originator_id', $1, true)", [originator_id])
    repo.query!("SELECT SET_CONFIG('versioning.origin', $1, true)", [origin])

    :ok
  end

  @spec authenticate_multi(multi :: Multi.t(), options :: Keyword.t()) :: Multi.t()
  def authenticate_multi(%Multi{} = multi, options \\ []) do
    Multi.new()
    |> Multi.run(:set_versioning_variables, fn repo, _changes ->
      :ok = run_authentication(repo, options)
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
  defp get_origin(pid \\ self()), do: RecursiveProcessDirectory.get([pid], {__MODULE__, :origin})

  @spec get_originator(pid :: pid()) :: originator | nil
  defp get_originator(pid \\ self()),
    do: RecursiveProcessDirectory.get([pid], {__MODULE__, :originator})
end
