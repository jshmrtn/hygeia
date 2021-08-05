defmodule Hygeia.AutoTracingContextTest do
  @moduledoc false

  use Hygeia.DataCase

  alias Hygeia.AutoTracingContext
  alias Hygeia.AutoTracingContext.AutoTracing
  alias Hygeia.Repo

  @moduletag origin: :test
  @moduletag originator: :noone

  describe "auto_tracing" do
    @valid_attrs %{current_step: :contact_methods}
    @update_attrs %{current_step: :covid_app}
    @invalid_attrs %{current_step: nil}

    test "list_auto_tracings/0 returns all auto_tracings" do
      auto_tracing = auto_tracing_fixture()
      assert AutoTracingContext.list_auto_tracings() == [auto_tracing]
    end

    test "get_auto_tracing!/1 returns the auto_tracing with given id" do
      auto_tracing = auto_tracing_fixture()
      assert AutoTracingContext.get_auto_tracing!(auto_tracing.uuid) == auto_tracing
    end

    test "create_auto_tracing/1 with valid data creates a auto_tracing" do
      case = case_fixture()

      assert {:ok, %AutoTracing{} = auto_tracing} =
               AutoTracingContext.create_auto_tracing(case, @valid_attrs)

      assert auto_tracing.current_step == :contact_methods

      auto_tracing = Repo.preload(auto_tracing, :case)
      assert auto_tracing.case.status == :first_contact
    end

    test "create_auto_tracing/1 with invalid data returns error changeset" do
      case = case_fixture()

      assert {:error, %Ecto.Changeset{}} =
               AutoTracingContext.create_auto_tracing(case, @invalid_attrs)
    end

    test "update_auto_tracing/2 with valid data updates the auto_tracing" do
      auto_tracing = auto_tracing_fixture()

      assert {:ok, %AutoTracing{} = auto_tracing} =
               AutoTracingContext.update_auto_tracing(auto_tracing, @update_attrs)

      assert auto_tracing.current_step == :covid_app
    end

    test "update_auto_tracing/2 with invalid data returns error changeset" do
      auto_tracing = auto_tracing_fixture()

      assert {:error, %Ecto.Changeset{}} =
               AutoTracingContext.update_auto_tracing(auto_tracing, @invalid_attrs)

      assert auto_tracing == AutoTracingContext.get_auto_tracing!(auto_tracing.uuid)
    end

    test "delete_auto_tracing/1 deletes the auto_tracing" do
      auto_tracing = auto_tracing_fixture()
      assert {:ok, %AutoTracing{}} = AutoTracingContext.delete_auto_tracing(auto_tracing)

      assert_raise Ecto.NoResultsError, fn ->
        AutoTracingContext.get_auto_tracing!(auto_tracing.uuid)
      end
    end

    test "change_auto_tracing/1 returns a auto_tracing changeset" do
      auto_tracing = auto_tracing_fixture()
      assert %Ecto.Changeset{} = AutoTracingContext.change_auto_tracing(auto_tracing)
    end
  end
end
