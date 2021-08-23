defmodule Hygeia.AuthorizationTest do
  @moduledoc false

  use Hygeia.DataCase

  import Hygeia.Authorization

  @moduletag origin: :test
  @moduletag originator: :noone

  describe "authorized?/4" do
    test "should allow tenant list for logged in user" do
      user = user_fixture(grants: [])

      assert authorized?(Hygeia.TenantContext.Tenant, :list, user)
    end

    test "should deny tenant details for logged in non-admin" do
      user = user_fixture(grants: [])
      tenant = tenant_fixture()

      refute authorized?(tenant, :details, user)
    end

    test "should allow tenant list for anonymous" do
      assert authorized?(Hygeia.TenantContext.Tenant, :list, :anonymous)
    end

    test "should allow tenant statistics for anonymous with public statistics" do
      tenant = tenant_fixture(%{public_statistics: true, iam_domain: "test"})

      assert authorized?(tenant, :statistics, :anonymous)
    end

    test "should deny tenant create for non-webmaster" do
      user = user_fixture(grants: [])

      refute authorized?(Hygeia.TenantContext.Tenant, :create, user)
      refute authorized?(Hygeia.TenantContext.Tenant, :create, :anonymous)
    end

    for action <- [:details, :update, :delete] do
      test "should deny person #{action} for non-admin" do
        person = person_fixture()
        user = user_fixture(grants: [])

        refute authorized?(person, unquote(action), :anonymous)
        refute authorized?(person, unquote(action), user)
      end
    end

    for action <- [:list, :create] do
      test "should deny person #{action} for non-tracer / non-supervisor / non-admin" do
        tenant = tenant_fixture()
        user = user_fixture(grants: [])

        refute authorized?(Hygeia.CaseContext.Person, unquote(action), :anonymous, tenant: tenant)
        refute authorized?(Hygeia.CaseContext.Person, unquote(action), user, tenant: tenant)
      end
    end

    for action <- [:details, :update, :delete] do
      test "should deny person #{action} for non-tracer / non-supervisor / non-admin" do
        person = person_fixture()
        user = user_fixture(grants: [])

        refute authorized?(person, unquote(action), :anonymous)
        refute authorized?(person, unquote(action), user)
      end
    end

    test "should deny person delete for tracer" do
      tenant = tenant_fixture()
      user = user_fixture(grants: [%{role: :tracer, tenant_uuid: tenant.uuid}])

      person = person_fixture(tenant)

      refute authorized?(person, :delete, user)
    end

    for role <- [:supervisor, :admin] do
      test "should allow person delete for #{role}" do
        tenant = tenant_fixture()
        person = person_fixture(tenant)
        user = user_fixture(grants: [%{role: unquote(role), tenant_uuid: tenant.uuid}])

        assert authorized?(person, :delete, user)
      end
    end

    for role <- [:tracer, :supervisor, :admin] do
      for action <- [:list, :create] do
        test "should allow person #{action} for #{role}" do
          tenant = tenant_fixture()
          user = user_fixture(grants: [%{role: unquote(role), tenant_uuid: tenant.uuid}])

          assert authorized?(Hygeia.CaseContext.Person, unquote(action), user, tenant: tenant)
        end
      end

      for action <- [:details, :update] do
        test "should allow person #{action} for #{role}" do
          tenant = tenant_fixture(%{iam_domain: "covid19-tracing.ch"})
          user = user_fixture(grants: [%{role: unquote(role), tenant_uuid: tenant.uuid}])

          person = person_fixture(tenant)

          assert authorized?(person, unquote(action), user)
        end
      end
    end

    for action <- [:list, :create] do
      test "should deny case #{action} for non-tracer / non-supervisor / non-admin" do
        tenant = tenant_fixture()
        user = user_fixture(grants: [])

        refute authorized?(Hygeia.CaseContext.Case, unquote(action), :anonymous, tenant: tenant)
        refute authorized?(Hygeia.CaseContext.Case, unquote(action), user, tenant: tenant)
      end
    end

    for action <- [:details, :update, :delete] do
      test "should deny case #{action} for non-tracer / non-supervisor / non-admin" do
        case = case_fixture()
        user = user_fixture(grants: [])

        refute authorized?(case, unquote(action), :anonymous)
        refute authorized?(case, unquote(action), user)
      end
    end

    test "should deny case delete for tracer" do
      tenant = tenant_fixture()
      user = user_fixture(grants: [%{role: :tracer, tenant_uuid: tenant.uuid}])

      case = case_fixture(person_fixture(tenant))

      refute authorized?(case, :delete, user)
    end

    for role <- [:supervisor, :admin] do
      test "should allow case delete for #{role}" do
        tenant = tenant_fixture()
        user = user_fixture(grants: [%{role: unquote(role), tenant_uuid: tenant.uuid}])

        case = case_fixture(person_fixture(tenant))

        assert authorized?(case, :delete, user)
      end
    end

    for role <- [:tracer, :supervisor, :admin] do
      for action <- [:list, :create] do
        test "should allow case #{action} for #{role}" do
          tenant = tenant_fixture()
          user = user_fixture(grants: [%{role: unquote(role), tenant_uuid: tenant.uuid}])

          assert authorized?(Hygeia.CaseContext.Case, unquote(action), user, tenant: tenant)
        end
      end

      for action <- [:details, :update] do
        test "should allow case #{action} for #{role}" do
          tenant = tenant_fixture(%{iam_domain: "covid19-tracing.ch"})
          user = user_fixture(grants: [%{role: unquote(role), tenant_uuid: tenant.uuid}])

          case = case_fixture(person_fixture(tenant))

          assert authorized?(case, unquote(action), user)
        end
      end
    end

    for action <- [:details, :update, :delete] do
      test "should deny transmission #{action} for non-tracer / non-supervisor / non-admin" do
        index_case = case_fixture()

        transmission =
          transmission_fixture(%{
            propagator_internal: true,
            propagator_case_uuid: index_case.uuid
          })

        user = user_fixture(grants: [])

        refute authorized?(transmission, unquote(action), :anonymous)
        refute authorized?(transmission, unquote(action), user)
      end
    end

    test "should deny transmission create for non-tracer / non-supervisor / non-admin" do
      user = user_fixture(grants: [])

      refute authorized?(Hygeia.CaseContext.Transmission, :create, :anonymous)
      refute authorized?(Hygeia.CaseContext.Transmission, :create, user)
    end

    test "should deny transmission delete for tracer" do
      tenant = tenant_fixture()
      user = user_fixture(grants: [%{role: :tracer, tenant_uuid: tenant.uuid}])

      index_case = case_fixture(person_fixture(tenant))

      transmission =
        transmission_fixture(%{
          propagator_internal: true,
          propagator_case_uuid: index_case.uuid
        })

      refute authorized?(transmission, :delete, user)
    end

    for role <- [:supervisor, :admin] do
      test "should allow transmission delete for #{role}" do
        tenant = tenant_fixture()
        user = user_fixture(grants: [%{role: unquote(role), tenant_uuid: tenant.uuid}])

        index_case = case_fixture(person_fixture(tenant))

        transmission =
          transmission_fixture(%{
            propagator_internal: true,
            propagator_case_uuid: index_case.uuid
          })

        assert authorized?(transmission, :delete, user)
      end
    end

    for role <- [:tracer, :supervisor, :admin] do
      for action <- [:details, :update] do
        test "should allow transmission #{action} for #{role}" do
          tenant = tenant_fixture()
          user = user_fixture(grants: [%{role: unquote(role), tenant_uuid: tenant.uuid}])

          index_case = case_fixture(person_fixture(tenant))

          transmission =
            transmission_fixture(%{
              propagator_internal: true,
              propagator_case_uuid: index_case.uuid
            })

          assert authorized?(transmission, unquote(action), user)
        end
      end

      test "should allow transmission create for #{role}" do
        tenant = tenant_fixture()
        user = user_fixture(grants: [%{role: unquote(role), tenant_uuid: tenant.uuid}])

        assert authorized?(Hygeia.CaseContext.Transmission, :create, user)
      end
    end

    for action <- [:list, :create] do
      test "should deny organisation #{action} for anonymous" do
        refute authorized?(Hygeia.OrganisationContext.Organisation, unquote(action), :anonymous)
      end
    end

    for action <- [:details, :update, :delete] do
      test "should deny organisation #{action} for anonymous" do
        organisation = organisation_fixture()
        refute authorized?(organisation, unquote(action), :anonymous)
      end
    end

    test "should deny organisation list for logged in user" do
      user = user_fixture(grants: [])

      refute authorized?(Hygeia.OrganisationContext.Organisation, :list, user)
    end

    test "should deny organisation create for logged in non-tracer / non-supervisor / non-admin" do
      user = user_fixture(grants: [])

      refute authorized?(Hygeia.OrganisationContext.Organisation, :create, user)
    end

    for role <- [:tracer, :supervisor, :admin] do
      for action <- [:list, :create] do
        test "should allow organisation #{action} for #{role}" do
          tenant = tenant_fixture()
          user = user_fixture(grants: [%{role: unquote(role), tenant_uuid: tenant.uuid}])

          assert authorized?(Hygeia.OrganisationContext.Organisation, unquote(action), user)
        end
      end

      for action <- [:details, :update, :delete] do
        test "should allow organisation #{action} for #{role}" do
          tenant = tenant_fixture()
          user = user_fixture(grants: [%{role: unquote(role), tenant_uuid: tenant.uuid}])

          organisation = organisation_fixture()

          assert authorized?(organisation, unquote(action), user)
        end
      end
    end

    for action <- [:list, :create] do
      test "should deny position #{action} for anonymous" do
        organisation = organisation_fixture()

        refute authorized?(Hygeia.OrganisationContext.Position, unquote(action), :anonymous, %{
                 organisation: organisation
               })
      end
    end

    test "should deny position delete for anonymous" do
      organisation = organisation_fixture()

      refute authorized?(organisation, :delete, :anonymous, %{organisation: organisation})
    end

    test "should allow position list for viewer" do
      tenant = tenant_fixture()
      user = user_fixture(grants: [%{role: :viewer, tenant_uuid: tenant.uuid}])
      organisation = organisation_fixture()

      assert authorized?(Hygeia.OrganisationContext.Position, :list, user, %{
               organisation: organisation
             })
    end

    test "should deny position create for logged in non-tracer / non-supervisor / non-admin" do
      user = user_fixture(grants: [])
      organisation = organisation_fixture()

      refute authorized?(Hygeia.OrganisationContext.Position, :create, user, %{
               organisation: organisation
             })
    end

    for role <- [:tracer, :supervisor, :admin] do
      for action <- [:list, :create] do
        test "should allow position #{action} for #{role}" do
          tenant = tenant_fixture()
          user = user_fixture(grants: [%{role: unquote(role), tenant_uuid: tenant.uuid}])

          organisation = organisation_fixture()

          assert authorized?(Hygeia.OrganisationContext.Position, unquote(action), user, %{
                   organisation: organisation
                 })
        end
      end

      test "should allow position delete for #{role}" do
        tenant = tenant_fixture()
        user = user_fixture(grants: [%{role: unquote(role), tenant_uuid: tenant.uuid}])

        position = position_fixture()

        assert authorized?(position, :delete, user)
      end
    end
  end
end
