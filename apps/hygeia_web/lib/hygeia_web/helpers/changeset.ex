defmodule HygeiaWeb.Helpers.Changeset do
  @moduledoc false

  import HygeiaWeb.ErrorHelpers
  import Phoenix.LiveView

  @spec changeset_error_flash(
          socket :: Phoenix.LiveView.Socket.t(),
          changeset :: Ecto.Changeset.t()
        ) :: Phoenix.LiveView.Socket.t()
  def changeset_error_flash(socket, changeset) do
    changeset
    |> Ecto.Changeset.traverse_errors(&translate_error/1)
    |> Enum.flat_map(fn {field, errors} ->
      Enum.map(errors, &{field, &1})
    end)
    |> Enum.reduce(socket, fn {field, error}, socket ->
      put_flash(socket, :error, "#{field}: #{error}")
    end)
  end
end
