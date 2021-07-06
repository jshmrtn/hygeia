defmodule HygeiaWeb.CaseLive.CreatePossibleIndex.FormSteps.DefineOptions do
  @moduledoc false

  use HygeiaWeb, :surface_live_component
  use Ecto.Schema

  import Ecto.Changeset
  import HygeiaGettext


  alias Surface.Components.Form.Checkbox
  alias Surface.Components.Form.ErrorTag
  alias Surface.Components.Form.Field
  alias Surface.Components.Form.Select
  alias Surface.Components.Form.HiddenInput

  embedded_schema do
  end

  prop current_form_data, :map, required: true
  prop is_internal_propagator, :boolean, required: true

  @impl Phoenix.LiveComponent
  def mount(socket) do
    {:ok,
     assign(socket,
       changeset: changeset(%__MODULE__{})
     )}
  end


  @impl Phoenix.LiveComponent
  def update(assigns, socket) do


    {:ok,
      socket
      |> assign(assigns)
    }
  end

  @spec changeset(schema :: %__MODULE__{}, attrs :: map()) ::
          Ecto.Changeset.t()
  def changeset(schema, attrs \\ %{}) do
    schema
    |> cast(attrs, [
    ])
  end
end
