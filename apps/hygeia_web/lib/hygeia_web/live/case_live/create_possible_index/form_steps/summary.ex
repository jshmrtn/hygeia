defmodule HygeiaWeb.CaseLive.CreatePossibleIndex.FormSteps.Summary do
  @moduledoc false

  use HygeiaWeb, :surface_live_component
  use Ecto.Schema

  import Ecto.Changeset
  import HygeiaGettext



  embedded_schema do
  end

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
