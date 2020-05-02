defmodule Peasant.AutomationsTest do
  use Peasant.GeneralCase

  alias Peasant.Automations

  @automations Peasant.Automation.domain()

  setup do
    Peasant.subscribe(@automations)
  end

  describe "list/0" do
    setup do
      {:ok, uuid} = Peasant.Automation.create(new_automation())
      [uuid: uuid]
    end

    test "should return all automations", %{uuid: uuid} do
      assert_receive %Peasant.Automation.Event.Created{automation: %{uuid: ^uuid}}
      assert [%Peasant.Automation.State{uuid: ^uuid}] = Automations.list()
    end
  end
end
