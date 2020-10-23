defmodule HygeiaWeb.TransmissionLiveTest do
  @moduledoc false

  use Hygeia.DataCase
  use HygeiaWeb.ConnCase

  import Phoenix.LiveViewTest

  alias HygeiaWeb.TransmissionLive.Index

  @moduletag origin: :test
  @moduletag originator: :noone
  @moduletag log_in: true

  describe "Index" do
    test "lists all transmissions" do
      propagator_case = case_fixture()

      transmission =
        transmission_fixture(%{
          propagator_internal: true,
          propagator_case_uuid: propagator_case.uuid,
          recipient_internal: false,
          recipient_ims_id: "IMS ID"
        })

      html = render_component(Index, id: :test, case: propagator_case)

      assert html =~ transmission.recipient_ims_id
    end
  end
end
