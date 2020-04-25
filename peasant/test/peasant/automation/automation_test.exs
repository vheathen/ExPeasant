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

  # describe "commit(automation_uuid, action, action_config \\ %{})" do
  #   @describetag :unit

  #   test "should run Handler.commit(automation_uuid, action)", %{automation: %{uuid: uuid}} do
  #     assert {:ok, _ref} = Peasant.Automation.commit(uuid, Peasant.Automation.Action.Attach)
  #     assert_receive {:commit, ^uuid, Peasant.Automation.Action.Attach, %{}}
  #   end

  #   test "should run Handler.commit(automation_uuid, action, config)", %{automation: %{uuid: uuid}} do
  #     config = %{key: "value"}

  #     assert {:ok, _ref} =
  #              Peasant.Automation.commit(
  #                uuid,
  #                Peasant.Automation.Action.Attach,
  #                config
  #              )

  #     assert_receive {:commit, ^uuid, Peasant.Automation.Action.Attach, ^config}
  #   end
  # end
end
