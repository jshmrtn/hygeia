defmodule HygeiaWeb.TransmissionLive.Header do
  @moduledoc false

  use HygeiaWeb, :surface_live_component

  alias Ecto.Changeset
  alias Hygeia.CaseContext.Transmission
  alias Hygeia.CaseContext.Transmission.InfectionPlace
  alias HygeiaWeb.UriActiveContext
  alias Surface.Components.LiveRedirect

  # Changeset or actual Tenant
  prop transmission, :map, required: true
  prop auth, :map, from_context: {HygeiaWeb, :auth}

  data display_name, :string

  @impl Phoenix.LiveComponent
  def update(
        %{transmission: %Changeset{data: data} = changeset} = _assigns,
        socket
      ) do
    {:ok,
     assign(socket,
       display_name: display_name(changeset),
       transmission: data
     )}
  end

  def update(%{transmission: %Transmission{} = transmission} = _assigns, socket) do
    {:ok,
     assign(socket,
       display_name: display_name(transmission),
       transmission: transmission
     )}
  end

  defp display_name(%Changeset{} = changeset),
    do:
      display_name(
        Changeset.get_field(changeset, :infection_place, %InfectionPlace{}).type,
        Changeset.get_field(changeset, :date)
      )

  defp display_name(
         %Transmission{infection_place: %InfectionPlace{type: type}, date: date} = _transmission
       ),
       do: display_name(type, date)

  defp display_name(type, date)
  defp display_name(type, nil), do: translate_infection_place_type(type)
  defp display_name(nil, date), do: Cldr.Date.to_string!(date, HygeiaCldr)

  defp display_name(type, date),
    do: "#{translate_infection_place_type(type)} / #{Cldr.Date.to_string!(date, HygeiaCldr)}"
end
