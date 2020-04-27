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

  describe "activate" do
    @describetag :unit

    test "should activate automation, reply :ok and {:continue, :activate}",
         %{automation_created: %{automation: automation}} do
      assert {:reply, :ok, %{automation | active: true}, {:continue, :activate}} ==
               Handler.handle_call(:activate, self(), automation)

      refute_receive _
    end

    test "with {:continue, :activate} should fire a Activated event and start an actual automation process",
         %{automation_created: %{automation: automation}} do
      assert {:noreply, automation} == Handler.handle_continue(:activate, automation)

      event = Event.Activated.new(automation_uuid: automation.uuid)

      assert_receive ^event
    end

    test "should reply :ok without :continue if automation already active",
         %{automation_created: %{automation: automation}} do
      assert {:reply, :ok, %{automation | active: true}} ==
               Handler.handle_call(:activate, self(), %{automation | active: true})

      refute_receive _
    end
  end

  describe "deactivate" do
    @describetag :unit

    test "should deactivate automation, reply :ok and {:continue, :deactivate}",
         %{automation_created: %{automation: automation}} do
      assert {:reply, :ok, automation, {:continue, :deactivate}} ==
               Handler.handle_call(:deactivate, self(), %{automation | active: true})

      refute_receive _
    end

    test "with {:continue, :deactivate} should fire a Deactivated event and start an actual automation process",
         %{automation_created: %{automation: automation}} do
      assert {:noreply, %{automation | active: true}} ==
               Handler.handle_continue(:deactivate, %{automation | active: true})

      event = Event.Deactivated.new(automation_uuid: automation.uuid)

      assert_receive ^event
    end

    test "should reply :ok without :continue if automation already inactive",
         %{automation_created: %{automation: automation}} do
      assert {:reply, :ok, automation} ==
               Handler.handle_call(:deactivate, self(), automation)

      refute_receive _
    end
  end

  describe "add step at" do
    @describetag :unit

    test "should add a given step at the requested position and increase :total_steps", %{
      automation: %{uuid: uuid, total_steps: total_steps} = automation
    } do
      # step 1

      step1 = new_step() |> Step.new()
      position = :first
      steps = [step1]

      step_added_at = Event.StepAddedAt.new(automation_uuid: uuid, step: step1, index: 0)

      assert {:reply, :ok, new_automation} =
               Handler.handle_call({:add_step_at, step1, position}, self(), automation)

      total_steps = total_steps + 1
      assert %{automation | steps: steps, total_steps: total_steps} == new_automation

      assert_receive ^step_added_at

      # step 2

      step2 = new_step() |> Step.new()
      position = 1
      steps = [step2, step1]

      step_added_at = Event.StepAddedAt.new(automation_uuid: uuid, step: step2, index: 0)

      assert {:reply, :ok, new_automation} =
               Handler.handle_call({:add_step_at, step2, position}, self(), new_automation)

      total_steps = total_steps + 1
      assert %{automation | steps: steps, total_steps: total_steps} == new_automation

      assert_receive ^step_added_at

      # step 3

      step3 = new_step() |> Step.new()
      position = :last
      steps = [step2, step1, step3]

      step_added_at = Event.StepAddedAt.new(automation_uuid: uuid, step: step3, index: -1)

      assert {:reply, :ok, new_automation} =
               Handler.handle_call({:add_step_at, step3, position}, self(), new_automation)

      total_steps = total_steps + 1
      assert %{automation | steps: steps, total_steps: total_steps} == new_automation

      assert_receive ^step_added_at

      # step 4

      step4 = new_step() |> Step.new()
      position = 2
      steps = [step2, step4, step1, step3]

      step_added_at =
        Event.StepAddedAt.new(automation_uuid: uuid, step: step4, index: position - 1)

      assert {:reply, :ok, new_automation} =
               Handler.handle_call({:add_step_at, step4, position}, self(), new_automation)

      total_steps = total_steps + 1
      assert %{automation | steps: steps, total_steps: total_steps} == new_automation

      assert_receive ^step_added_at
    end

    test "should return {:error, :active_automation_cannot_be_altered}", %{
      automation: %{uuid: uuid} = automation
    } do
      # step 1

      automation = %{automation | active: true}

      step = new_step() |> Step.new()
      position = :first

      step_added_at = Event.StepAddedAt.new(automation_uuid: uuid, step: step, index: 0)

      assert {:reply, {:error, :active_automation_cannot_be_altered}, automation} ==
               Handler.handle_call({:add_step_at, step, position}, self(), automation)

      refute_receive ^step_added_at
    end
  end

  describe "delete step" do
    @describetag :unit

    test "should delete a step with given id", %{
      automation: automation
    } do
      # step 1

      steps =
        1..10
        |> Enum.map(fn _ ->
          new_step() |> Step.new()
        end)

      1..10
      |> Enum.reduce(steps, fn _, steps ->
        assert %{uuid: step_uuid} = Enum.random(steps)
        total_steps = Enum.count(steps)
        step_index = Enum.find_index(steps, &(&1.uuid == step_uuid))
        new_steps = List.delete_at(steps, step_index)
        new_total_steps = Enum.count(new_steps)

        assert {:reply, :ok, %{automation | steps: new_steps, total_steps: new_total_steps}} ==
                 Handler.handle_call({:delete_step, step_uuid}, self(), %{
                   automation
                   | steps: steps,
                     total_steps: total_steps
                 })

        step_deleted =
          Event.StepDeleted.new(automation_uuid: automation.uuid, step_uuid: step_uuid)

        assert_receive ^step_deleted

        new_steps
      end)
    end

    test "should return :ok event if step with given id doesn't exist but no any notifications",
         %{
           automation: automation
         } do
      step_uuid = UUID.uuid4()

      assert {:reply, :ok, automation} ==
               Handler.handle_call({:delete_step, step_uuid}, self(), automation)

      refute_receive _
    end

    test "should return {:error, :active_automation_cannot_be_altered}", %{
      automation: automation
    } do
      # step 1

      step = new_step_struct()

      automation = %{automation | active: true, steps: [step]}

      step_deleted = Event.StepDeleted.new(automation_uuid: automation.uuid, step_uuid: step.uuid)

      assert {:reply, {:error, :active_automation_cannot_be_altered}, automation} ==
               Handler.handle_call({:delete_step, step.uuid}, self(), automation)

      refute_receive ^step_deleted
    end
  end

  describe "rename step" do
    @describetag :unit

    test "should rename a step with given id", %{
      automation: automation
    } do
      step = new_step() |> Step.new()

      new_name = new_word(step.name)

      automation = %{automation | steps: [step]}
      new_automation = %{automation | steps: [%{step | name: new_name}]}

      step_renamed =
        Event.StepRenamed.new(
          automation_uuid: automation.uuid,
          step_uuid: step.uuid,
          name: new_name
        )

      assert {:reply, :ok, new_automation} ==
               Handler.handle_call({:rename_step, step.uuid, new_name}, self(), automation)

      assert_receive ^step_renamed
    end

    test "should return :ok if a step with given id already has given name", %{
      automation: automation
    } do
      step = new_step() |> Step.new()

      new_name = step.name

      automation = %{automation | steps: [step]}

      step_renamed =
        Event.StepRenamed.new(
          automation_uuid: automation.uuid,
          step_uuid: step.uuid,
          name: new_name
        )

      assert {:reply, :ok, automation} ==
               Handler.handle_call({:rename_step, step.uuid, new_name}, self(), automation)

      refute_receive ^step_renamed
    end

    test "should return {:error, :no_such_step_exists} step with given id doesn't exist but no any notifications",
         %{
           automation: automation
         } do
      step_uuid = UUID.uuid4()
      new_name = new_word()

      assert {:reply, {:error, :no_such_step_exists}, automation} ==
               Handler.handle_call({:rename_step, step_uuid, new_name}, self(), automation)

      refute_receive _
    end

    test "should return {:error, :active_automation_cannot_be_altered}", %{
      automation: automation
    } do
      # step 1

      step = new_step_struct()
      new_name = new_word()

      automation = %{automation | active: true, steps: [step]}

      step_deleted = Event.StepRenamed.new(automation_uuid: automation.uuid, step_uuid: step.uuid)

      assert {:reply, {:error, :active_automation_cannot_be_altered}, automation} ==
               Handler.handle_call({:rename_step, step.uuid, new_name}, self(), automation)

      refute_receive ^step_deleted
    end
  end

  describe "move step to" do
    @describetag :unit

    test "should move a step with given id to the given position", %{
      automation: automation
    } do
      step1 = new_step_struct()
      step2 = new_step_struct()
      step3 = new_step_struct()
      step4 = new_step_struct()

      # to_position1 = :first
      # step_to_move1 = step2
      # steps1 = [step2, step1, step3, step4]

      # to_position2 = :last
      # step_to_move2 = step1
      # steps2 = [step2, step3, step4, step1]

      # to_position3 = 1
      # step_to_move3 = step1
      # steps3 = [step1, step2, step3, step4]

      # to_position4 = 3
      # step_to_move4 = step2
      # steps4 = [step1, step3, step2, step4]

      to_p = [:first, :last, 1, 3]
      indx = [0, -1, 0, 2]
      st_to_m = [step2.uuid, step1.uuid, step1.uuid, step2.uuid]

      steps0 = [step1, step2, step3, step4]

      stps = [
        [step2, step1, step3, step4],
        [step2, step3, step4, step1],
        [step1, step2, step3, step4],
        [step1, step3, step2, step4]
      ]

      0..3
      |> Enum.reduce(steps0, fn i, steps ->
        event =
          Event.StepMovedTo.new(
            automation_uuid: automation.uuid,
            step_uuid: Enum.at(st_to_m, i),
            index: Enum.at(indx, i)
          )

        new_steps = Enum.at(stps, i)

        assert {:reply, :ok, %{automation | steps: new_steps}} ==
                 Handler.handle_call(
                   {:move_step_to, Enum.at(st_to_m, i), Enum.at(to_p, i)},
                   self(),
                   %{automation | steps: steps}
                 )

        assert_receive ^event

        new_steps
      end)
    end

    test "should return :ok and no notification if step is already at the given position", %{
      automation: automation
    } do
      step = new_step_struct()

      automation = %{automation | steps: [step], total_steps: 1}

      assert {:reply, :ok, automation} ==
               Handler.handle_call(
                 {:move_step_to, step.uuid, :last},
                 self(),
                 automation
               )

      refute_receive _
    end

    test "should return {:error, :no_such_step_exists} step with given id doesn't exist but no any notifications",
         %{
           automation: automation
         } do
      step = new_step_struct()
      other_uuid = UUID.uuid4()

      automation = %{automation | steps: [step], total_steps: 1}

      assert {:reply, {:error, :no_such_step_exists}, automation} ==
               Handler.handle_call(
                 {:move_step_to, other_uuid, :last},
                 self(),
                 automation
               )

      refute_receive _
    end

    test "should return {:error, :active_automation_cannot_be_altered}", %{
      automation: automation
    } do
      step = new_step_struct()

      automation = %{automation | active: true, steps: [step], total_steps: 1}

      assert {:reply, {:error, :active_automation_cannot_be_altered}, automation} ==
               Handler.handle_call(
                 {:move_step_to, step.uuid, :last},
                 self(),
                 automation
               )

      refute_receive _
    end
  end

  describe "activate step" do
    @describetag :unit

    test "should set :active to true for a step with given id", %{
      automation: automation
    } do
      step = new_step() |> Step.new()

      automation = %{automation | steps: [step]}

      new_automation = %{automation | steps: [%{step | active: true}]}

      step_activated =
        Event.StepActivated.new(
          automation_uuid: automation.uuid,
          step_uuid: step.uuid
        )

      assert {:reply, :ok, new_automation} ==
               Handler.handle_call({:activate_step, step.uuid}, self(), automation)

      assert_receive ^step_activated
    end

    test "should return :ok if a step with given id already activated", %{
      automation: automation
    } do
      step = new_step(active: true) |> Step.new()

      automation = %{automation | steps: [step]}

      assert {:reply, :ok, automation} ==
               Handler.handle_call({:activate_step, step.uuid}, self(), automation)

      refute_receive _
    end

    test "should return {:error, :no_such_step_exists} step with given id doesn't exist but no any notifications",
         %{
           automation: automation
         } do
      step_uuid = UUID.uuid4()

      assert {:reply, {:error, :no_such_step_exists}, automation} ==
               Handler.handle_call({:activate_step, step_uuid}, self(), automation)

      refute_receive _
    end

    test "should return {:error, :active_automation_cannot_be_altered}", %{
      automation: automation
    } do
      # step 1

      step = new_step_struct()

      automation = %{automation | active: true, steps: [step]}

      assert {:reply, {:error, :active_automation_cannot_be_altered}, automation} ==
               Handler.handle_call({:activate_step, step.uuid}, self(), automation)

      refute_receive _
    end
  end

  describe "deactivate step" do
    @describetag :unit

    test "should set :active to false for a step with given id", %{
      automation: automation
    } do
      step = new_step() |> Step.new()

      automation = %{automation | steps: [%{step | active: true}]}

      new_automation = %{automation | steps: [step]}

      step_deactivated =
        Event.StepDeactivated.new(
          automation_uuid: automation.uuid,
          step_uuid: step.uuid
        )

      assert {:reply, :ok, new_automation} ==
               Handler.handle_call({:deactivate_step, step.uuid}, self(), automation)

      assert_receive ^step_deactivated
    end

    test "should return :ok if a step with given id already deactivated", %{
      automation: automation
    } do
      step = new_step() |> Step.new()

      automation = %{automation | steps: [step]}

      assert {:reply, :ok, automation} ==
               Handler.handle_call({:deactivate_step, step.uuid}, self(), automation)

      refute_receive _
    end

    test "should return {:error, :no_such_step_exists} step with given id doesn't exist but no any notifications",
         %{
           automation: automation
         } do
      step_uuid = UUID.uuid4()

      assert {:reply, {:error, :no_such_step_exists}, automation} ==
               Handler.handle_call({:deactivate_step, step_uuid}, self(), automation)

      refute_receive _
    end

    test "should return {:error, :active_automation_cannot_be_altered}", %{
      automation: automation
    } do
      # step 1

      step = new_step_struct(active: true)

      automation = %{automation | active: true, steps: [step]}

      assert {:reply, {:error, :active_automation_cannot_be_altered}, automation} ==
               Handler.handle_call({:deactivate_step, step.uuid}, self(), automation)

      refute_receive _
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

  def new_word(word \\ nil) do
    case Faker.Lorem.word() do
      ^word -> new_word(word)
      new_word -> new_word
    end
  end
end
