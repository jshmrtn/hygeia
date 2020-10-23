defmodule Hygeia.Helpers.Versioning do
  @moduledoc false

  alias Hygeia.UserContext.User

  case Mix.env() do
    :test -> @type origin :: :web | :api | :test
    _env -> @type origin :: :web | :api
  end

  @type originator :: User.t() | :noone

  @spec versioning_extract({:error, reason}) :: {:error, reason} when reason: term
  @spec versioning_extract({:ok, %{model: resource, version: %PaperTrail.Version{}}}) ::
          {:ok, resource}
        when resource: term

  def versioning_extract({:error, reason}), do: {:error, reason}

  def versioning_extract({:ok, %{model: model}}), do: {:ok, model}

  @spec versioning_insert(changeset :: Ecto.Changeset.t()) ::
          {:ok, %{model: resource, version: %PaperTrail.Version{}}} | {:error, Ecto.Changeset.t()}
        when resource: term
  def versioning_insert(changeset) do
    PaperTrail.insert(changeset, get_paper_trail_options())
  end

  @spec versioning_update(changeset :: Ecto.Changeset.t()) ::
          {:ok, %{model: resource, version: %PaperTrail.Version{}}} | {:error, Ecto.Changeset.t()}
        when resource: term
  def versioning_update(changeset) do
    PaperTrail.update(changeset, get_paper_trail_options())
  end

  @spec versioning_delete(changeset :: Ecto.Changeset.t()) ::
          {:ok, %{model: resource, version: %PaperTrail.Version{}}} | {:error, Ecto.Changeset.t()}
        when resource: term
  def versioning_delete(changeset) do
    PaperTrail.delete(changeset, get_paper_trail_options())
  end

  @spec put_origin(origin :: origin) :: :ok
  def put_origin(origin) do
    Process.put({__MODULE__, :origin}, origin)
    :ok
  end

  @spec put_originator(originator :: originator) :: :ok
  def put_originator(originator) when is_struct(originator, User) or originator == :noone do
    Process.put({__MODULE__, :originator}, originator)
    :ok
  end

  defp get_paper_trail_options do
    [
      origin:
        case get_origin() do
          nil -> raise "Origin must be set to mutate resources"
          origin when is_atom(origin) -> Atom.to_string(origin)
        end,
      originator:
        case get_originator() do
          nil -> raise "Originator must be set to mutate resources"
          :noone -> nil
          %User{uuid: originator_uuid} -> %{id: originator_uuid}
        end
    ]
  end

  @spec get_origin :: origin | nil
  defp get_origin, do: Process.get({__MODULE__, :origin})

  @spec get_originator :: originator | nil
  defp get_originator, do: Process.get({__MODULE__, :originator})
end
