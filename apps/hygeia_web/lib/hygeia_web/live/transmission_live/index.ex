defmodule HygeiaWeb.TransmissionLive.Index do
  @moduledoc false

  use HygeiaWeb, :live_component

  alias Hygeia.Repo

  @impl Phoenix.LiveComponent
  def update(%{case: case} = assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign(
       :case,
       Repo.preload(case, propagated_transmissions: [recipient_case: [person: []]])
     )}
  end
end
