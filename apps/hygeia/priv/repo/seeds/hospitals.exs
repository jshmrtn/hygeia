import Hygeia.OrganisationContext

alias Hygeia.Helpers.Versioning
alias Hygeia.Repo

{:ok, hospitals} =
  :hygeia
  |> Application.app_dir("priv/repo/seeds/hospitals.csv")
  |> File.stream!()
  |> CSV.decode!(headers: true)
  |> Stream.map(
    &%{
      name: &1["name"],
      type: :healthcare,
      address: %{
        address: &1["address"],
        zip: &1["zip"],
        place: &1["place"],
        country: &1["country"],
        subdivision: &1["subdivision"]
      }
    }
  )
  |> Stream.map(&change_new_organisation/1)
  |> Enum.reduce(Ecto.Multi.new(), &Ecto.Multi.insert(&2, make_ref(), &1))
  |> Versioning.authenticate_multi()
  |> Repo.transaction()

hospitals |> Map.values() |> Enum.filter(&is_struct(&1, Hygeia.OrganisationContext.Organisation))
