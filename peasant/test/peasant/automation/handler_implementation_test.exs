defmodule Peasant.Automation.HandlerImplementationTest do
  use Peasant.DataCase

  alias Peasant.Automation.State
  alias Peasant.Automation.State.Step
  alias Peasant.Automation.Handler
  alias Peasant.Automation.Event

  # alias Peasant.Automations.FakeAutomation
  # alias Peasant.Automation.Action

  setup do
    Peasant.subscribe("automations")
    :ok
  end

  setup [:automation_setup, :created_setup]

  describe "creation process" do
    @describetag :unit

    test "init(%{new: true} = automation) should return %{new: false} = automation as a state and {:continue, :created}",
         %{automation: automation} do
      assert {:ok, %{automation | new: false}, {:continue, :created}} == Handler.init(automation)
    end

    test "should notify about automation creation", %{
      automation_created: %{automation: automation} = automation_created
    } do
      assert {:noreply, %{automation | new: false}} ==
               Handler.handle_continue(:created, automation)

      assert_receive ^automation_created
    end
  end

  describe "rename" do
    @describetag :unit

    test "should rename automation, reply :ok and fire Renamed event",
         %{automation_created: %{automation: automation}} do
      new_name = Faker.Lorem.word()

      assert {:reply, :ok, %{automation | name: new_name}} ==
               Handler.handle_call({:rename, new_name}, self(), automation)

      renamed = Event.Renamed.new(automation_uuid: automation.uuid, name: new_name)

      assert_receive ^renamed
    end

    test "should reply :ok and do not fire Renamed event if name is the same",
         %{automation_created: %{automation: %{name: name} = automation}} do
      assert {:reply, :ok, automation} ==
               Handler.handle_call({:rename, name}, self(), automation)

      refute_receive _
    end
  end

  describe "add step at" do
    @describetag :unit

    test "should add a given step at the requested position", %{
      automation: %{uuid: uuid} = automation
    } do
      # step 1

      step1 = new_step() |> Step.new()
      position = :first
      steps = [step1]

      step_added_at = Event.StepAddedAt.new(automation_uuid: uuid, step: step1, index: 0)

      assert {:reply, :ok, new_automation} =
               Handler.handle_call({:add_step_at, step1, position}, self(), automation)

      assert %{automation | steps: steps} == new_automation

      assert_receive ^step_added_at

      # step 2

      step2 = new_step() |> Step.new()
      position = 1
      steps = [step2, step1]

      step_added_at = Event.StepAddedAt.new(automation_uuid: uuid, step: step2, index: 0)

      assert {:reply, :ok, new_automation} =
               Handler.handle_call({:add_step_at, step2, position}, self(), new_automation)

      assert %{automation | steps: steps} == new_automation

      assert_receive ^step_added_at

      # step 3

      step3 = new_step() |> Step.new()
      position = :last
      steps = [step2, step1, step3]

      step_added_at = Event.StepAddedAt.new(automation_uuid: uuid, step: step3, index: -1)

      assert {:reply, :ok, new_automation} =
               Handler.handle_call({:add_step_at, step3, position}, self(), new_automation)

      assert %{automation | steps: steps} == new_automation

      assert_receive ^step_added_at

      # step 4

      step4 = new_step() |> Step.new()
      position = 2
      steps = [step2, step4, step1, step3]

      step_added_at =
        Event.StepAddedAt.new(automation_uuid: uuid, step: step4, index: position - 1)

      assert {:reply, :ok, new_automation} =
               Handler.handle_call({:add_step_at, step4, position}, self(), new_automation)

      assert %{automation | steps: steps} == new_automation

      assert_receive ^step_added_at
    end
  end

  def created_setup(%{automation: automation}) do
    automation_created =
      Event.Created.new(
        automation_uuid: automation.uuid,
        automation: %{automation | new: false}
      )

    [automation_created: automation_created]
  end

  def automation_setup(_context) do
    automation = new_automation() |> State.new()

    [automation: automation]
  end
end
