defmodule Hygeia.UserContextTest do
  @moduledoc false

  use Hygeia.DataCase

  alias Hygeia.UserContext

  @moduletag origin: :test
  @moduletag originator: :noone

  describe "user" do
    alias Hygeia.UserContext.User

    @valid_attrs %{
      display_name: "some display_name",
      email: "some_email@example.com",
      iam_sub: "8fe86005-b3c6-4d7c-9746-53e090d05e48"
    }
    @update_attrs %{
      display_name: "some updated display_name",
      email: "some_updated_email@example.com",
      iam_sub: "a05fb916-8c5a-4b3a-928c-59b50d9bbef8"
    }
    @invalid_attrs %{display_name: nil, email: nil, iam_sub: nil}

    test "list_users/0 returns all user" do
      user = user_fixture()
      assert UserContext.list_users() |> List.first() |> Repo.preload(:grants) == user
    end

    test "get_user!/1 returns the user with given id" do
      user = user_fixture()
      assert Repo.preload(UserContext.get_user!(user.uuid), :grants) == user
    end

    test "create_user/1 with valid data creates a user" do
      tenant = tenant_fixture()

      assert {:ok, %User{} = user} =
               UserContext.create_user(
                 Map.put_new(@valid_attrs, :grants, [%{role: :tracer, tenant_uuid: tenant.uuid}])
               )

      assert user.display_name == "some display_name"
      assert user.email == "some_email@example.com"
      assert user.iam_sub == "8fe86005-b3c6-4d7c-9746-53e090d05e48"
    end

    test "create_user/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = UserContext.create_user(@invalid_attrs)
    end

    test "update_user/2 with valid data updates the user" do
      user = user_fixture()
      assert {:ok, %User{} = user} = UserContext.update_user(user, @update_attrs)
      assert user.display_name == "some updated display_name"
      assert user.email == "some_updated_email@example.com"
      assert user.iam_sub == "a05fb916-8c5a-4b3a-928c-59b50d9bbef8"
    end

    test "update_user/2 with invalid data returns error changeset" do
      user = user_fixture()
      assert {:error, %Ecto.Changeset{}} = UserContext.update_user(user, @invalid_attrs)
      assert user == Repo.preload(UserContext.get_user!(user.uuid), :grants)
    end

    test "delete_user/1 deletes the user" do
      user = user_fixture()
      assert {:ok, %User{}} = UserContext.delete_user(user)
      assert_raise Ecto.NoResultsError, fn -> UserContext.get_user!(user.uuid) end
    end

    test "change_user/1 returns a user changeset" do
      user = user_fixture()
      assert %Ecto.Changeset{} = UserContext.change_user(user)
    end
  end
end
