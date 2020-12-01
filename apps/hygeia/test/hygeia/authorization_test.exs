defmodule Hygeia.AuthorizationTest do
  @moduledoc false

  use Hygeia.DataCase

  import Hygeia.Authorization

  @moduletag origin: :test
  @moduletag originator: :noone

  describe "authorized?/4" do
    test "should allow tenant list for logged in user" do
      user = user_fixture(roles: [])

      assert authorized?(Hygeia.TenantContext.Tenant, :list, user)
    end

    test "should deny tenant details for logged in non-admin" do
      user = user_fixture(roles: [])
      tenant = tenant_fixture()

      refute authorized?(tenant, :details, user)
    end

    test "should allow tenant list for anonymous" do
      assert authorized?(Hygeia.TenantContext.Tenant, :list, :anonymous)
    end

    test "should allow tenant statistics for anonymous with public statistics" do
      tenant = tenant_fixture(%{public_statistics: true})

      assert authorized?(tenant, :statistics, :anonymous)
    end

    test "should deny tenant create for non-admin" do
      user = user_fixture(roles: [])

      refute authorized?(Hygeia.TenantContext.Tenant, :create, user)
      refute authorized?(Hygeia.TenantContext.Tenant, :create, :anonymous)
    end

    for action <- [:details, :update, :delete] do
      test "should deny person #{action} for non-admin" do
        person = person_fixture()
        user = user_fixture(roles: [])

        refute authorized?(person, unquote(action), :anonymous)
        refute authorized?(person, unquote(action), user)
      end

      test "should deny person #{action} for admin" do
        person = person_fixture()
        user = user_fixture(roles: [:admin])

        assert authorized?(person, unquote(action), user)
      end
    end

    for action <- [:list, :create] do
      test "should deny person #{action} for non-tracer / non-supervisor / non-admin" do
        user = user_fixture(roles: [])

        refute authorized?(Hygeia.CaseContext.Person, unquote(action), :anonymous)
        refute authorized?(Hygeia.CaseContext.Person, unquote(action), user)
      end
    end

    for action <- [:details, :update, :delete] do
      test "should deny person #{action} for non-tracer / non-supervisor / non-admin" do
        person = person_fixture()
        user = user_fixture(roles: [])

        refute authorized?(person, unquote(action), :anonymous)
        refute authorized?(person, unquote(action), user)
      end
    end

    test "should deny person delete for tracer" do
      person = person_fixture()
      user = user_fixture(roles: [:tracer])

      refute authorized?(person, :delete, user)
    end

    for role <- [:supervisor, :admin] do
      test "should allow person delete for #{role}" do
        person = person_fixture()
        user = user_fixture(roles: [unquote(role)])

        assert authorized?(person, :delete, user)
      end
    end

    for role <- [:tracer, :supervisor, :admin] do
      for action <- [:list, :create] do
        test "should allow person #{action} for #{role}" do
          user = user_fixture(roles: [unquote(role)])

          assert authorized?(Hygeia.CaseContext.Person, unquote(action), user)
        end
      end

      for action <- [:details, :update] do
        test "should allow person #{action} for #{role}" do
          person = person_fixture()
          user = user_fixture(roles: [unquote(role)])

          assert authorized?(person, unquote(action), user)
        end
      end
    end

    for action <- [:list, :create] do
      test "should deny case #{action} for non-tracer / non-supervisor / non-admin" do
        user = user_fixture(roles: [])

        refute authorized?(Hygeia.CaseContext.Case, unquote(action), :anonymous)
        refute authorized?(Hygeia.CaseContext.Case, unquote(action), user)
      end
    end

    for action <- [:details, :update, :delete] do
      test "should deny case #{action} for non-tracer / non-supervisor / non-admin" do
        case = case_fixture()
        user = user_fixture(roles: [])

        refute authorized?(case, unquote(action), :anonymous)
        refute authorized?(case, unquote(action), user)
      end
    end

    test "should deny case delete for tracer" do
      case = case_fixture()
      user = user_fixture(roles: [:tracer])

      refute authorized?(case, :delete, user)
    end

    for role <- [:supervisor, :admin] do
      test "should allow case delete for #{role}" do
        case = case_fixture()
        user = user_fixture(roles: [unquote(role)])

        assert authorized?(case, :delete, user)
      end
    end

    for role <- [:tracer, :supervisor, :admin] do
      for action <- [:list, :create] do
        test "should allow case #{action} for #{role}" do
          user = user_fixture(roles: [unquote(role)])

          assert authorized?(Hygeia.CaseContext.Case, unquote(action), user)
        end
      end

      for action <- [:details, :update] do
        test "should allow case #{action} for #{role}" do
          case = case_fixture()
          user = user_fixture(roles: [unquote(role)])

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

        user = user_fixture(roles: [])

        refute authorized?(transmission, unquote(action), :anonymous)
        refute authorized?(transmission, unquote(action), user)
      end
    end

    test "should deny transmission create for non-tracer / non-supervisor / non-admin" do
      user = user_fixture(roles: [])

      refute authorized?(Hygeia.CaseContext.Transmission, :create, :anonymous)
      refute authorized?(Hygeia.CaseContext.Transmission, :create, user)
    end

    test "should deny transmission delete for tracer" do
      index_case = case_fixture()

      transmission =
        transmission_fixture(%{
          propagator_internal: true,
          propagator_case_uuid: index_case.uuid
        })

      user = user_fixture(roles: [:tracer])

      refute authorized?(transmission, :delete, user)
    end

    for role <- [:supervisor, :admin] do
      test "should allow transmission delete for #{role}" do
        index_case = case_fixture()

        transmission =
          transmission_fixture(%{
            propagator_internal: true,
            propagator_case_uuid: index_case.uuid
          })

        user = user_fixture(roles: [unquote(role)])

        assert authorized?(transmission, :delete, user)
      end
    end

    for role <- [:tracer, :supervisor, :admin] do
      for action <- [:details, :update] do
        test "should allow transmission #{action} for #{role}" do
          index_case = case_fixture()

          transmission =
            transmission_fixture(%{
              propagator_internal: true,
              propagator_case_uuid: index_case.uuid
            })

          user = user_fixture(roles: [unquote(role)])

          assert authorized?(transmission, unquote(action), user)
        end
      end

      test "should allow transmission create for #{role}" do
        user = user_fixture(roles: [unquote(role)])

        assert authorized?(Hygeia.CaseContext.Transmission, :create, user)
      end
    end

    test "should deny protocol entry list for non-tracer / non-supervisor / non-admin" do
      case = case_fixture()
      user = user_fixture(roles: [])

      refute authorized?(Hygeia.CaseContext.ProtocolEntry, :list, :anonymous, %{case: case})
      refute authorized?(Hygeia.CaseContext.ProtocolEntry, :list, user, %{case: case})
    end

    for role <- [:tracer, :supervisor, :admin] do
      test "should allow protocol entry list for #{role}" do
        case = case_fixture()
        user = user_fixture(roles: [unquote(role)])

        assert authorized?(Hygeia.CaseContext.ProtocolEntry, :list, user, %{case: case})
      end
    end

    test "should deny protocol entry create for non-tracer / non-supervisor / non-admin" do
      case = case_fixture()
      user = user_fixture(roles: [])

      refute authorized?(Hygeia.CaseContext.ProtocolEntry, :create, :anonymous, %{case: case})
      refute authorized?(Hygeia.CaseContext.ProtocolEntry, :create, user, %{case: case})
    end

    for role <- [:tracer, :supervisor, :admin] do
      test "should allow protocol entry create for #{role}" do
        case = case_fixture()
        user = user_fixture(roles: [unquote(role)])

        assert authorized?(Hygeia.CaseContext.ProtocolEntry, :create, user, %{case: case})
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

    test "should allow organisation list for logged in user" do
      user = user_fixture(roles: [])

      assert authorized?(Hygeia.OrganisationContext.Organisation, :list, user)
    end

    test "should deny organisation create for logged in non-tracer / non-supervisor / non-admin" do
      user = user_fixture(roles: [])

      refute authorized?(Hygeia.OrganisationContext.Organisation, :create, user)
    end

    for role <- [:tracer, :supervisor, :admin] do
      for action <- [:list, :create] do
        test "should allow organisation #{action} for #{role}" do
          user = user_fixture(roles: [unquote(role)])

          assert authorized?(Hygeia.OrganisationContext.Organisation, unquote(action), user)
        end
      end

      for action <- [:details, :update, :delete] do
        test "should allow organisation #{action} for #{role}" do
          organisation = organisation_fixture()
          user = user_fixture(roles: [unquote(role)])

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

    test "should allow position list for logged in user" do
      user = user_fixture(roles: [])
      organisation = organisation_fixture()

      assert authorized?(Hygeia.OrganisationContext.Position, :list, user, %{
               organisation: organisation
             })
    end

    test "should deny position create for logged in non-tracer / non-supervisor / non-admin" do
      user = user_fixture(roles: [])
      organisation = organisation_fixture()

      refute authorized?(Hygeia.OrganisationContext.Position, :create, user, %{
               organisation: organisation
             })
    end

    for role <- [:tracer, :supervisor, :admin] do
      for action <- [:list, :create] do
        test "should allow position #{action} for #{role}" do
          user = user_fixture(roles: [unquote(role)])
          organisation = organisation_fixture()

          assert authorized?(Hygeia.OrganisationContext.Position, unquote(action), user, %{
                   organisation: organisation
                 })
        end
      end

      test "should allow position delete for #{role}" do
        position = position_fixture()
        user = user_fixture(roles: [unquote(role)])

        assert authorized?(position, :delete, user)
      end
    end

    test "should allow profession list for anyone" do
      user = user_fixture(roles: [])

      assert authorized?(Hygeia.CaseContext.Profession, :list, :anonymous)
      assert authorized?(Hygeia.CaseContext.Profession, :list, user)
    end

    test "should allow profession details for anyone" do
      profession = profession_fixture()
      user = user_fixture(roles: [])

      assert authorized?(profession, :details, :anonymous)
      assert authorized?(profession, :details, user)
    end

    test "should deny profession create for anyone" do
      user = user_fixture(roles: [])

      refute authorized?(Hygeia.CaseContext.Profession, :create, :anonymous)
      refute authorized?(Hygeia.CaseContext.Profession, :create, user)
    end

    for action <- [:update, :delete] do
      test "should deny profession #{action} for non-admin" do
        profession = profession_fixture()
        user = user_fixture(roles: [])

        refute authorized?(profession, unquote(action), :anonymous)
        refute authorized?(profession, unquote(action), user)
      end
    end

    test "should allow profession create for admin" do
      user = user_fixture(roles: [:admin])

      assert authorized?(Hygeia.CaseContext.Profession, :create, user)
    end

    for action <- [:details, :update, :delete] do
      test "should allow profession #{action} for admin" do
        profession = profession_fixture()
        user = user_fixture(roles: [:admin])

        assert authorized?(profession, unquote(action), user)
      end
    end

    test "should allow infection_place_type list for anyone" do
      user = user_fixture(roles: [])

      assert authorized?(Hygeia.CaseContext.InfectionPlaceType, :list, :anonymous)
      assert authorized?(Hygeia.CaseContext.InfectionPlaceType, :list, user)
    end

    test "should allow infection_place_type details for anyone" do
      infection_place_type = infection_place_type_fixture()
      user = user_fixture(roles: [])

      assert authorized?(infection_place_type, :details, :anonymous)
      assert authorized?(infection_place_type, :details, user)
    end

    test "should deny infection_place_type create for anyone" do
      user = user_fixture(roles: [])

      refute authorized?(Hygeia.CaseContext.InfectionPlaceType, :create, :anonymous)
      refute authorized?(Hygeia.CaseContext.InfectionPlaceType, :create, user)
    end

    for action <- [:update, :delete] do
      test "should deny infection_place_type #{action} for non-admin" do
        infection_place_type = infection_place_type_fixture()
        user = user_fixture(roles: [])

        refute authorized?(infection_place_type, unquote(action), :anonymous)
        refute authorized?(infection_place_type, unquote(action), user)
      end
    end

    test "should allow infection_place_type create for admin" do
      user = user_fixture(roles: [:admin])

      assert authorized?(Hygeia.CaseContext.InfectionPlaceType, :create, user)
    end

    for action <- [:details, :update, :delete] do
      test "should allow infection_place_type #{action} for admin" do
        infection_place_type = infection_place_type_fixture()
        user = user_fixture(roles: [:admin])

        assert authorized?(infection_place_type, unquote(action), user)
      end
    end
  end
end
