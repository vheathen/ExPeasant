defmodule Peasant.AutomationsTest do
  use Peasant.GeneralCase

  alias Peasant.Automations

  @automations Peasant.Automation.domain()

  setup do
    Peasant.subscribe(@automations)
  end

  setup do
    {:ok, uuid} = Peasant.Automation.create(new_automation())

    assert_receive %Peasant.Automation.Event.Created{automation: %{uuid: ^uuid}}

    [uuid: uuid]
  end

  describe "get/1" do
    test "should return an automation with a given uuid", %{uuid: uuid} do
      assert %Peasant.Automation.State{uuid: ^uuid} = Automations.get(uuid)
    end
  end

  describe "list/0" do
    test "should return all automations", %{uuid: uuid} do
      assert [%Peasant.Automation.State{uuid: ^uuid}] = Automations.list()
    end
  end
end
