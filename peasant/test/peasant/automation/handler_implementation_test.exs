defmodule Peasant.Automation.HandlerImplementationTest do
  use Peasant.DataCase

  alias Peasant.Automation.State
  alias Peasant.Automation.Handler

  # alias Peasant.Automations.FakeAutomation
  # alias Peasant.Automation.Action

  setup do
    Peasant.subscribe("automations")
    :ok
  end

  setup :automation_setup

  describe "creation process" do
    @describetag :unit

    setup :created_setup

    test "init(%{new: true} = automation) should return %{new: false} = automation as a state and {:continue, :created}",
         %{automation: automation} do
      assert {:ok, %{automation | new: false}, {:continue, :created}} == Handler.init(automation)
    end

    test "should notify about automation creation", %{
      automation_created: %{details: %{automation: automation}} = automation_created
    } do
      assert {:noreply, %{automation | new: false}} ==
               Handler.handle_continue(:created, automation)

      assert_receive ^automation_created
    end
  end

  def created_setup(%{automation: automation}) do
    automation_created =
      Peasant.Automation.Event.Created.new(
        automation_uuid: automation.uuid,
        details: %{automation: %{automation | new: false}}
      )

    [automation_created: automation_created]
  end

  def automation_setup(_context) do
    automation = new_automation() |> State.new()

    [automation: automation]
  end
end
