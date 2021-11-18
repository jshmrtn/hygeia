defmodule Hygeia.OrganisationContextFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Hygeia.OrganisationContext` context.
  """

  @doc """
  Generate a visit.
  """
  def visit_fixture(attrs \\ %{}) do
    {:ok, visit} =
      attrs
      |> Enum.into(%{

      })
      |> Hygeia.OrganisationContext.create_visit()

    visit
  end
end
