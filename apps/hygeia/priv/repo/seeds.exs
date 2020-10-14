# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Hygeia.Repo.insert!(%Hygeia.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

import Hygeia.UserContext

alias Hygeia.Helpers.Versioning

Versioning.put_origin(:web)
Versioning.put_originator(:noone)

{:ok, _user_1} =
  create_user(%{
    email: "user@example.com",
    display_name: "Test User",
    iam_sub: "8fe86005-b3c6-4d7c-9746-53e090d05e48"
  })
