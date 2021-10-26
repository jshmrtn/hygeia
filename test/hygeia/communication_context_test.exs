defmodule Hygeia.CommunicationContextTest do
  @moduledoc false

  use Hygeia.DataCase

  alias Hygeia.CommunicationContext
  alias Hygeia.CommunicationContext.Email
  alias Hygeia.CommunicationContext.SMS

  @moduletag origin: :test
  @moduletag originator: :noone

  describe "emails" do
    @valid_attrs %{
      direction: :outgoing,
      last_try: ~N[2010-04-17 14:00:00],
      message: "some message",
      status: :success
    }
    @update_attrs %{
      direction: :outgoing,
      last_try: ~N[2011-05-18 15:01:01],
      message: "some updated message",
      status: :permanent_failure
    }
    @invalid_attrs %{direction: nil, last_try: nil, message: nil, status: nil}

    test "list_emails/0 returns all emails" do
      %Email{uuid: email_uuid} = email_fixture()
      assert [%Email{uuid: ^email_uuid}] = CommunicationContext.list_emails()
    end

    test "get_emails!/1 returns the email with given id" do
      email = %Email{uuid: email_uuid} = email_fixture()
      assert %Email{uuid: ^email_uuid} = CommunicationContext.get_email!(email.uuid)
    end

    test "create_email/1 with valid data creates an email" do
      assert {:ok, %Email{} = email} =
               CommunicationContext.create_email(case_fixture(), @valid_attrs)

      assert email.direction == :outgoing
      assert email.last_try == ~U[2010-04-17 14:00:00.000000Z]
      assert email.message == "some message"
      assert email.status == :success
    end

    test "create_email/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} =
               CommunicationContext.create_email(case_fixture(), @invalid_attrs)
    end

    test "update_email/2 with valid data updates the emails" do
      email = email_fixture()
      assert {:ok, %Email{} = email} = CommunicationContext.update_email(email, @update_attrs)
      assert email.direction == :outgoing
      assert email.last_try == ~U[2011-05-18 15:01:01.000000Z]
      assert email.message == "some updated message"
      assert email.status == :permanent_failure
    end

    test "update_email/2 with invalid data returns error changeset" do
      email = email_fixture()

      assert {:error, %Ecto.Changeset{}} =
               CommunicationContext.update_email(email, @invalid_attrs)
    end

    test "change_email/1 returns a email changeset" do
      email = email_fixture()
      assert %Ecto.Changeset{} = CommunicationContext.change_email(email)
    end
  end

  describe "sms" do
    @valid_attrs %{
      direction: :outgoing,
      message: "some message",
      number: "+41 78 724 57 90",
      status: :success
    }
    @update_attrs %{
      direction: :outgoing,
      message: "some updated message",
      status: :failure
    }
    @invalid_attrs %{direction: nil, message: nil, status: nil}

    test "list_sms/0 returns all sms" do
      sms = sms_fixture()
      assert CommunicationContext.list_sms() == [sms]
    end

    test "get_sms!/1 returns the sms with given id" do
      sms = sms_fixture()
      assert CommunicationContext.get_sms!(sms.uuid) == sms
    end

    test "create_sms/1 with valid data creates an sms" do
      assert {:ok, %SMS{} = sms} = CommunicationContext.create_sms(case_fixture(), @valid_attrs)

      assert sms.direction == :outgoing
      assert sms.message == "some message"
      assert sms.status == :success
    end

    test "create_sms/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} =
               CommunicationContext.create_sms(case_fixture(), @invalid_attrs)
    end

    test "update_sms/2 with valid data updates the sms" do
      sms = sms_fixture()
      assert {:ok, %SMS{} = sms} = CommunicationContext.update_sms(sms, @update_attrs)
      assert sms.direction == :outgoing
      assert sms.message == "some updated message"
      assert sms.status == :failure
    end

    test "update_sms/2 with invalid data returns error changeset" do
      sms = sms_fixture()

      assert {:error, %Ecto.Changeset{}} = CommunicationContext.update_sms(sms, @invalid_attrs)

      assert sms == CommunicationContext.get_sms!(sms.uuid)
    end

    test "change_sms/1 returns a sms changeset" do
      sms = sms_fixture()
      assert %Ecto.Changeset{} = CommunicationContext.change_sms(sms)
    end
  end
end
