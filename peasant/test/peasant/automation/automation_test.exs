defmodule Peasant.AutomationTest do
  use Peasant.GeneralCase

  alias Peasant.Automation

  alias Peasant.Automation.State

  setup_all do
    automation_handler = Application.get_env(:peasant, :automation_handler)
    Application.put_env(:peasant, :automation_handler, Peasant.Automation.FakeHandler)

    on_exit(fn ->
      Application.put_env(:peasant, :automation_handler, automation_handler)
    end)
  end

  setup do
    automation_spec = new_automation()

    assert %State{} = automation = State.new(automation_spec)

    [automation_spec: automation_spec, automation: automation]
  end

  describe "Automation module" do
    @describetag :unit

    test "should intoduce State struct and functions", do: :ok
  end

  describe "Creation and create/1" do
    @describetag :unit

    test "should return {:ok, uuid} in case of correct automation specs", %{
      automation_spec: automation_spec
    } do
      assert {:ok, uuid} = Automation.create(automation_spec)
      assert is_binary(uuid)
      assert {:ok, _} = UUID.info(uuid)

      assert_receive {:create, %State{uuid: ^uuid}}
    end

    test "should return {:error, error} in case of incorrect automation specs" do
      automation = new_automation() |> Map.delete(:name)
      assert {:error, _} = Automation.create(automation)

      refute_receive {:create, %State{}}
    end
  end

  # describe "delete(automation_uuid)" do
  #   @describetag :unit

  #   test "should run Handler.delete(automation_uuid)", %{automation: %{uuid: uuid}} do
  #     assert :ok = Automation.delete(uuid)
  #     assert_receive {:delete, ^uuid}
  #   end
  # end

  describe "rename/2" do
    @describetag :unit
    test "should run Handler.rename(uuid, new_name)", %{automation: %{uuid: uuid}} do
      new_name = Faker.Lorem.word()
      assert :ok = Automation.rename(uuid, new_name)
      assert_receive {:rename, ^uuid, ^new_name}
    end
  end
end
