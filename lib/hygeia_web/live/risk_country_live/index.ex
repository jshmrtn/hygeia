defmodule HygeiaWeb.RiskCountryLive.Index do
  @moduledoc false

  use HygeiaWeb, :surface_view
  use Hygeia, :model

  alias Hygeia.EctoType.Country
  alias Hygeia.RiskCountryContext
  alias Hygeia.RiskCountryContext.RiskCountry

  alias Surface.Components.Context
  alias Surface.Components.Form
  alias Surface.Components.Form.Checkbox
  alias Surface.Components.Form.Field
  alias Surface.Components.Form.HiddenInput
  alias Surface.Components.Form.Inputs
  alias Surface.Components.LiveRedirect

  alias Phoenix.LiveView.Socket

  @primary_key false
  embedded_schema do
    embeds_many :countries, PossibleRiskCountry, primary_key: false do
      field :country, Country
      field :is_risk_country, :boolean
    end
  end

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    socket =
      if (socket.assigns.live_action != :edit and
            authorized?(RiskCountry, :list, get_auth(socket))) or
           (socket.assigns.live_action == :edit and
              authorized?(RiskCountry, :create, get_auth(socket)) and
              authorized?(RiskCountry, :update, get_auth(socket)) and
              authorized?(RiskCountry, :delete, get_auth(socket))) do
        Phoenix.PubSub.subscribe(Hygeia.PubSub, "risk_countries")

        assign(socket,
          changeset: changeset(%__MODULE__{}, %{countries: get_countries()}),
          page_title: gettext("List of high risk countries")
        )
      else
        socket
        |> push_redirect(to: Routes.home_index_path(socket, :index))
        |> put_flash(:error, gettext("You are not authorized to do this action."))
      end

    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def handle_event(
        "remove_country",
        %{"country" => country_code},
        %Socket{assigns: %{changeset: changeset}} = socket
      ) do
    countries =
      changeset
      |> fetch_field!(:countries)
      |> Enum.map(
        &if match?(^country_code, &1.country), do: %{&1 | is_risk_country: false}, else: &1
      )

    {:noreply,
     assign(socket,
       changeset: %Ecto.Changeset{put_embed(changeset, :countries, countries) | action: :validate}
     )}
  end

  @impl Phoenix.LiveView
  def handle_event(
        "validate",
        %{"index" => selected_countries},
        %Socket{assigns: %{changeset: changeset}} = socket
      ) do
    {:noreply,
     assign(socket,
       changeset: %Ecto.Changeset{changeset(changeset, selected_countries) | action: :validate}
     )}
  end

  @impl Phoenix.LiveView
  def handle_event(
        "save",
        %{"index" => selected_countries},
        %Socket{assigns: %{changeset: changeset}} = socket
      ) do
    true =
      authorized?(RiskCountry, :create, get_auth(socket)) and
        authorized?(RiskCountry, :delete, get_auth(socket)) and
        authorized?(RiskCountry, :update, get_auth(socket))

    changeset
    |> changeset(selected_countries)
    |> apply_action(:validate)
    |> case do
      {:ok, selected_countries} ->
        risk_countries =
          selected_countries
          |> Map.get(:countries, [])
          |> Enum.filter(& &1.is_risk_country)
          |> Enum.map(& &1.country)

        {:ok, _any} = RiskCountryContext.patch_risk_countries(risk_countries)

        {:noreply, push_redirect(socket, to: Routes.risk_country_index_path(socket, :index))}

      {:error, changeset} ->
        {:noreply,
         assign(socket,
           changeset: %Ecto.Changeset{changeset | action: :validate}
         )}
    end
  end

  @impl Phoenix.LiveView
  def handle_info({_type, %RiskCountry{}, _version}, socket) do
    {:noreply, assign(socket, risk_countries: RiskCountryContext.list_risk_countries())}
  end

  def handle_info(_other, socket), do: {:noreply, socket}

  defp get_countries do
    all_countries = countries()
    risk_country_codes = Enum.map(RiskCountryContext.list_risk_countries(), & &1.country)

    Enum.map(all_countries, fn {_name, code} ->
      if code in risk_country_codes do
        %{country: code, is_risk_country: true}
      else
        %{country: code, is_risk_country: false}
      end
    end)
  end

  defp changeset(schema, attrs) do
    schema
    |> cast(attrs, [])
    |> cast_embed(:countries, with: &selected_risk_country_changeset/2)
  end

  defp selected_risk_country_changeset(schema, attrs) do
    cast(schema, attrs, [:country, :is_risk_country])
  end
end
