defmodule Hygeia.ImportContextTest do
  @moduledoc false

  use Hygeia.DataCase

  alias Hygeia.ImportContext
  alias Hygeia.ImportContext.Import
  alias Hygeia.ImportContext.Row

  @moduletag origin: :test
  @moduletag originator: :noone

  @mime MIME.type("xlsx")
  @path Application.app_dir(:hygeia, "priv/test/import/example_ism_2021_06_11_test.xlsx")

  describe "imports" do
    @valid_attrs %{type: :ism_2021_06_11_test}
    @update_attrs %{type: :ism_2021_06_11_death}
    @invalid_attrs %{type: nil}

    test "list_imports/0 returns all imports" do
      import = import_fixture()
      assert ImportContext.list_imports() == [import]
    end

    test "get_import!/1 returns the import with given id" do
      import = import_fixture()
      assert ImportContext.get_import!(import.uuid) == import
    end

    test "create_import/1 with valid data creates a import" do
      assert {:ok, %Import{} = import} =
               ImportContext.create_import(tenant_fixture(), @valid_attrs)

      assert import.type == :ism_2021_06_11_test
    end

    test "create_import/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} =
               ImportContext.create_import(tenant_fixture(), @invalid_attrs)
    end

    @mime MIME.type("xlsx")
    @path Application.app_dir(:hygeia, "priv/test/import/example_ism_2021_06_11_test.xlsx")
    @external_resource @path

    test "create_import/3 with valid ism_2021_06_11_test xlsx imports correctly" do
      assert {:ok, %Import{} = import} =
               ImportContext.create_import(tenant_fixture(), @mime, @path, %{
                 type: :ism_2021_06_11_test
               })

      assert %Import{
               rows: [
                 %Row{
                   identifiers: %{"Fall ID" => 2_182_953}
                 }
                 | _other_rows
               ]
             } = Repo.preload(import, :rows)
    end

    @mime MIME.type("csv")
    @path Application.app_dir(:hygeia, "priv/test/import/example_ism_2021_06_11_test.csv")
    @external_resource @path

    test "create_import/3 with valid ism_2021_06_11_test csv imports correctly" do
      assert {:ok, %Import{} = import} =
               ImportContext.create_import(tenant_fixture(), @mime, @path, %{
                 type: :ism_2021_06_11_test
               })

      assert %Import{
               rows: [
                 %Row{
                   identifiers: %{"Fall ID" => "2291418"}
                 }
               ]
             } = Repo.preload(import, :rows)
    end

    test "passes with valid tracer / supervisor" do
      tenant = tenant_fixture()

      tracer =
        user_fixture(iam_sub: "tracer", grants: [%{role: :tracer, tenant_uuid: tenant.uuid}])

      supervisor =
        user_fixture(
          iam_sub: "supervisor",
          grants: [%{role: :supervisor, tenant_uuid: tenant.uuid}]
        )

      assert {:ok, _import} =
               ImportContext.create_import(tenant, %{
                 type: :ism_2021_06_11_test,
                 default_tracer_uuid: tracer.uuid,
                 default_supervisor_uuid: supervisor.uuid
               })
    end

    test "fails with invalid tracer" do
      tenant = tenant_fixture()

      tracer = user_fixture(iam_sub: "tracer", grants: [])

      supervisor =
        user_fixture(
          iam_sub: "supervisor",
          grants: [%{role: :supervisor, tenant_uuid: tenant.uuid}]
        )

      assert {:error, changeset} =
               ImportContext.create_import(tenant, %{
                 type: :ism_2021_06_11_test,
                 default_tracer_uuid: tracer.uuid,
                 default_supervisor_uuid: supervisor.uuid
               })

      assert "is invalid" in errors_on(changeset).default_tracer_uuid
    end

    test "fails with invalid supervisor" do
      tenant = tenant_fixture()

      tracer =
        user_fixture(iam_sub: "tracer", grants: [%{role: :tracer, tenant_uuid: tenant.uuid}])

      supervisor = user_fixture(iam_sub: "supervisor", grants: [])

      assert {:error, changeset} =
               ImportContext.create_import(tenant, %{
                 type: :ism_2021_06_11_test,
                 default_tracer_uuid: tracer.uuid,
                 default_supervisor_uuid: supervisor.uuid
               })

      assert "is invalid" in errors_on(changeset).default_supervisor_uuid
    end

    test "update_import/2 with valid data updates the import" do
      import = import_fixture()
      assert {:ok, %Import{} = import} = ImportContext.update_import(import, @update_attrs)
      assert import.type == :ism_2021_06_11_death
    end

    test "update_import/2 with invalid data returns error changeset" do
      import = import_fixture()
      assert {:error, %Ecto.Changeset{}} = ImportContext.update_import(import, @invalid_attrs)
      assert import == ImportContext.get_import!(import.uuid)
    end

    test "delete_import/1 deletes the import" do
      import = import_fixture()
      assert {:ok, %Import{}} = ImportContext.delete_import(import)
      assert_raise Ecto.NoResultsError, fn -> ImportContext.get_import!(import.uuid) end
    end

    test "change_import/1 returns a import changeset" do
      import = import_fixture()
      assert %Ecto.Changeset{} = ImportContext.change_import(import)
    end
  end

  describe "rows" do
    @valid_attrs %{corrected: %{}, identifiers: %{}, data: %{}, status: :pending}
    @update_attrs %{corrected: %{}, identifiers: %{}, data: %{}, status: :discarded}
    @invalid_attrs %{corrected: nil, identifiers: nil, data: nil, status: nil}

    test "list_rows/0 returns all rows" do
      _row = row_fixture()
      assert [%Row{}] = ImportContext.list_rows()
    end

    test "get_row!/1 returns the row with given id" do
      row = row_fixture()
      assert %Row{} = ImportContext.get_row!(row.uuid)
    end

    test "create_row/1 with valid data creates a row" do
      assert {:ok, %Row{} = row} = ImportContext.create_row(import_fixture(), @valid_attrs)
      assert row.corrected == %{}
      assert row.identifiers == %{}
      assert row.data == %{}
      assert row.status == :pending
    end

    test "create_row/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} =
               ImportContext.create_row(import_fixture(), @invalid_attrs)
    end

    test "update_row/2 with valid data updates the row" do
      row = row_fixture()

      assert {:ok, %Row{} = row} = ImportContext.update_row(row, @update_attrs)

      assert row.corrected == %{}
      assert row.identifiers == %{}
      assert row.data == %{}
      assert row.status == :discarded
    end

    test "update_row/2 with invalid data returns error changeset" do
      row = row_fixture()

      assert {:error, %Ecto.Changeset{}} = ImportContext.update_row(row, @invalid_attrs)

      assert %Row{} = ImportContext.get_row!(row.uuid)
    end

    test "delete_row/1 deletes the row" do
      row = row_fixture()
      assert {:ok, %Row{}} = ImportContext.delete_row(row)
      assert_raise Ecto.NoResultsError, fn -> ImportContext.get_row!(row.uuid) end
    end

    test "change_row/1 returns a row changeset" do
      row = row_fixture()
      assert %Ecto.Changeset{} = ImportContext.change_row(row)
    end

    test "get_row_predecessor/1 find preceeding row" do
      tenant = tenant_fixture()

      import_1 =
        import_fixture(tenant, %{type: :ism_2021_06_11_test, change_date: ~N[2021-01-01 08:00:00]})

      row_11 =
        row_fixture(import_1, %{
          data: %{"Fall ID" => 77},
          identifiers: %{"Fall ID" => 77},
          status: :resolved
        })

      _row_12 =
        row_fixture(import_1, %{
          data: %{"Fall ID" => 88},
          identifiers: %{"Fall ID" => 88},
          status: :resolved
        })

      import_2 =
        import_fixture(tenant, %{type: :ism_2021_06_11_test, change_date: ~N[2021-01-02 08:00:00]})

      _row_21 =
        row_fixture(import_2, %{
          data: %{"Fall ID" => 77, "v" => 2},
          identifiers: %{"Fall ID" => 77}
        })

      import_3 =
        import_fixture(tenant, %{type: :ism_2021_06_11_test, change_date: ~N[2021-01-03 08:00:00]})

      row_31 =
        row_fixture(import_3, %{
          data: %{"Fall ID" => 77, "v" => 3},
          identifiers: %{"Fall ID" => 77}
        })

      row_11_uuid = row_11.uuid

      assert %Row{uuid: ^row_11_uuid} = ImportContext.get_row_predecessor(row_31)
    end

    test "import same rows, rows keep link to original import" do
      tenant = tenant_fixture()

      {:ok, import_1} =
        ImportContext.create_import(tenant, @mime, @path, %{
          type: :ism_2021_06_11_test
        })

      {:ok, import_2} =
        ImportContext.create_import(tenant, @mime, @path, %{
          type: :ism_2021_06_11_test
        })

      import_1_rows =
        import_1
        |> Repo.preload(rows: [:imports])
        |> Map.get(:rows)

      import_2_rows =
        import_2
        |> Repo.preload(rows: [:imports])
        |> Map.get(:rows)

      assert length(import_1_rows) == length(import_2_rows) and
               length(import_2_rows) == length(Repo.all(Row))

      assert %Row{
               imports: [_, _]
             } = List.first(import_1_rows)

      assert %Row{
               imports: [_, _]
             } = List.first(import_2_rows)
    end
  end
end
