defmodule Hygeia.CaseContextTest do
  @moduledoc false

  use Hygeia.DataCase

  alias Hygeia.CaseContext
  alias Hygeia.CaseContext.Profession

  describe "professions" do
    @valid_attrs %{name: "some name"}
    @update_attrs %{name: "some updated name"}
    @invalid_attrs %{name: nil}

    test "list_professions/0 returns all professions" do
      profession = profession_fixture()
      assert CaseContext.list_professions() == [profession]
    end

    test "get_profession!/1 returns the profession with given id" do
      profession = profession_fixture()
      assert CaseContext.get_profession!(profession.uuid) == profession
    end

    test "create_profession/1 with valid data creates a profession" do
      assert {:ok, %Profession{} = profession} = CaseContext.create_profession(@valid_attrs)
      assert profession.name == "some name"
    end

    test "create_profession/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = CaseContext.create_profession(@invalid_attrs)
    end

    test "update_profession/2 with valid data updates the profession" do
      profession = profession_fixture()

      assert {:ok, %Profession{} = profession} =
               CaseContext.update_profession(profession, @update_attrs)

      assert profession.name == "some updated name"
    end

    test "update_profession/2 with invalid data returns error changeset" do
      profession = profession_fixture()

      assert {:error, %Ecto.Changeset{}} =
               CaseContext.update_profession(profession, @invalid_attrs)

      assert profession == CaseContext.get_profession!(profession.uuid)
    end

    test "delete_profession/1 deletes the profession" do
      profession = profession_fixture()
      assert {:ok, %Profession{}} = CaseContext.delete_profession(profession)
      assert_raise Ecto.NoResultsError, fn -> CaseContext.get_profession!(profession.uuid) end
    end

    test "change_profession/1 returns a profession changeset" do
      profession = profession_fixture()
      assert %Ecto.Changeset{} = CaseContext.change_profession(profession)
    end
  end
end
