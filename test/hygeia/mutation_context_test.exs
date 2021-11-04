defmodule Hygeia.MutationContextTest do
  @moduledoc false

  use Hygeia.DataCase

  alias Hygeia.MutationContext
  alias Hygeia.MutationContext.Mutation

  @moduletag origin: :test
  @moduletag originator: :noone

  describe "mutations" do
    @valid_attrs %{name: "some name", ism_code: 42}
    @update_attrs %{name: "some updated name", ism_code: 143}
    @invalid_attrs %{name: nil, ism_code: nil}

    test "list_mutations/0 returns all mutations" do
      mutation = mutation_fixture()
      assert MutationContext.list_mutations() == [mutation]
    end

    test "get_mutation!/1 returns the mutation with given id" do
      mutation = mutation_fixture()
      assert MutationContext.get_mutation!(mutation.uuid) == mutation
    end

    test "create_mutation/1 with valid data creates a mutation" do
      assert {:ok, %Mutation{} = mutation} = MutationContext.create_mutation(@valid_attrs)
      assert mutation.name == "some name"
      assert mutation.ism_code == 42
    end

    test "create_mutation/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = MutationContext.create_mutation(@invalid_attrs)
    end

    test "update_mutation/2 with valid data updates the mutation" do
      mutation = mutation_fixture()

      assert {:ok, %Mutation{} = mutation} =
               MutationContext.update_mutation(mutation, @update_attrs)

      assert mutation.name == "some updated name"
      assert mutation.ism_code == 143
    end

    test "update_mutation/2 with invalid data returns error changeset" do
      mutation = mutation_fixture()

      assert {:error, %Ecto.Changeset{}} =
               MutationContext.update_mutation(mutation, @invalid_attrs)

      assert mutation == MutationContext.get_mutation!(mutation.uuid)
    end

    test "delete_mutation/1 deletes the mutation" do
      mutation = mutation_fixture()
      assert {:ok, %Mutation{}} = MutationContext.delete_mutation(mutation)
      assert_raise Ecto.NoResultsError, fn -> MutationContext.get_mutation!(mutation.uuid) end
    end

    test "change_mutation/1 returns a mutation changeset" do
      mutation = mutation_fixture()
      assert %Ecto.Changeset{} = MutationContext.change_mutation(mutation)
    end
  end
end
