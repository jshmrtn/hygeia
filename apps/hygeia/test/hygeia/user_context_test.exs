defmodule Hygeia.UserContextTest do
  @moduledoc false

  use Hygeia.DataCase

  alias Hygeia.UserContext

  describe "user" do
    alias Hygeia.UserContext.User

    @valid_attrs %{
      display_name: "some display_name",
      email: "some email",
      iam_sub: "8fe86005-b3c6-4d7c-9746-53e090d05e48"
    }
    @update_attrs %{
      display_name: "some updated display_name",
      email: "some updated email",
      iam_sub: "a05fb916-8c5a-4b3a-928c-59b50d9bbef8"
    }
    @invalid_attrs %{display_name: nil, email: nil, iam_sub: nil}

    test "list_users/0 returns all user" do
      user = user_fixture()
      assert UserContext.list_users() == [user]
    end

    test "get_user!/1 returns the user with given id" do
      user = user_fixture()
      assert UserContext.get_user!(user.uuid) == user
    end

    test "create_user/1 with valid data creates a user" do
      assert {:ok, %User{} = user} = UserContext.create_user(@valid_attrs)
      assert user.display_name == "some display_name"
      assert user.email == "some email"
      assert user.iam_sub == "8fe86005-b3c6-4d7c-9746-53e090d05e48"
    end

    test "create_user/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = UserContext.create_user(@invalid_attrs)
    end

    test "update_user/2 with valid data updates the user" do
      user = user_fixture()
      assert {:ok, %User{} = user} = UserContext.update_user(user, @update_attrs)
      assert user.display_name == "some updated display_name"
      assert user.email == "some updated email"
      assert user.iam_sub == "a05fb916-8c5a-4b3a-928c-59b50d9bbef8"
    end

    test "update_user/2 with invalid data returns error changeset" do
      user = user_fixture()
      assert {:error, %Ecto.Changeset{}} = UserContext.update_user(user, @invalid_attrs)
      assert user == UserContext.get_user!(user.uuid)
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
