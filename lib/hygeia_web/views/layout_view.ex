defmodule HygeiaWeb.LayoutView do
  use HygeiaWeb, :view

  defp sentry_enabled?,
    do: Sentry.Config.environment_name() in Sentry.Config.included_environments()

  defp sentry_user(conn) do
    conn
    |> get_auth()
    |> case do
      :anonymous ->
        %{}

      %Hygeia.UserContext.User{
        uuid: id,
        email: email,
        display_name: name
      } ->
        %{id: id, email: email, name: name}

      %Hygeia.CaseContext.Person{
        uuid: id,
        first_name: first_name,
        last_name: last_name
      } ->
        %{id: id, name: "#{String.slice(first_name, 0..0)}. #{String.slice(last_name, 0..0)}."}
    end
    |> Jason.encode!()
  end
end
