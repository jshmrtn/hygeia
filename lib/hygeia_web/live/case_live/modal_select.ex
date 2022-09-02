defmodule HygeiaWeb.CaseLive.ModalSelect do
  @moduledoc false

  use HygeiaWeb, :surface_live_component

  alias Ecto.UUID
  alias Phoenix.HTML.FormData
  alias Surface.Components.Form
  alias Surface.Components.Form.Field
  alias Surface.Components.Form.HiddenInput

  @doc "An identifier for the form"
  prop form, :form, from_context: {Form, :form}

  @doc "An identifier for the associated field"
  prop field, :atom, from_context: {Field, :field}

  prop title, :string, default: ""
  prop options, :list, default: []
  prop disabled, :boolean, default: false

  slot default, arg: %{value: :any}

  data input_id, :string
  data query, :string, default: ""
  data modal_open, :boolean, default: false
  data filtered_options, :list, default: []

  @impl Phoenix.LiveComponent
  def mount(socket) do
    {:ok,
     assign(socket,
       input_id: "choose_" <> UUID.generate()
     )}
  end

  @impl Phoenix.LiveComponent
  def update(%{options: options} = assigns, socket) do
    socket = assign(socket, assigns)

    socket =
      case socket.assigns.query do
        "" -> assign(socket, filtered_options: options)
        _query -> socket
      end

    {:ok, socket}
  end

  @impl Phoenix.LiveComponent
  def handle_event("open_modal", _params, socket) do
    {:noreply, assign(socket, modal_open: true)}
  end

  @impl Phoenix.LiveComponent
  def handle_event("close_modal", _params, socket) do
    {:noreply, assign(socket, modal_open: false)}
  end

  @impl Phoenix.LiveComponent
  def handle_event("query", %{"value" => value} = _params, socket) do
    query_lowercase = String.downcase(value)

    filtered_options =
      Enum.filter(
        socket.assigns.options,
        &String.contains?(String.downcase(elem(&1, 0)), query_lowercase)
      )

    {:noreply, assign(socket, query: value, filtered_options: filtered_options)}
  end

  @impl Phoenix.LiveComponent
  def handle_event("choose", params, socket) do
    {
      :noreply,
      socket
      |> assign(modal_open: false)
      |> push_event("new_value", %{
        input_id: socket.assigns.input_id,
        value: params["uuid"]
      })
    }
  end

  defp value_tuple(form, field, options) do
    value =
      case FormData.input_value(form.source, form, field) do
        "" -> nil
        value -> value
      end

    Enum.find(
      options,
      {"", ""},
      &(elem(&1, 1) == value)
    )
  end
end
