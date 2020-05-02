defmodule Peasant.Automation.HandlerImplementationTest do
  use Peasant.GeneralCase

  import Peasant.Collection.TestHelper

  alias Peasant.Automation.State
  alias Peasant.Automation.State.Step
  alias Peasant.Automation.Handler
  alias Peasant.Automation.Event

  @automations Peasant.Automation.domain()

  setup do
    Peasant.subscribe(@automations)
    # GenServer.stop(Peasant.Collection.Observer.Automations)
  end

  setup [:automation_setup, :created_setup]

  describe "persist" do
    @describetag :unit

    test "should persist current state and continue with the given next action",
         %{automation: automation} do
      assert {:noreply, stored_automation, {:continue, :created}} =
               Handler.handle_continue({:persist, :created}, automation)

      assert automation == stored_automation |> nilify_timestamps()

      assert stored_automation == Peasant.Repo.get(automation.uuid, @automations)
      assert stored_automation == Peasant.Collection.Keeper.get_by_id(automation.uuid)
    end

    test "should persist current state and stop if no next_action or it is nil",
         %{automation: automation} do
      assert {:noreply, stored_automation} = Handler.handle_continue(:persist, automation)

      assert automation == stored_automation |> nilify_timestamps()

      assert stored_automation == Peasant.Repo.get(automation.uuid, @automations)
      assert stored_automation == Peasant.Collection.Keeper.get_by_id(automation.uuid)
    end
  end

  describe "creation process" do
    @describetag :unit

    test "init(%{new: true} = automation) should return {:ok, %{automation | new: false}, {:continue, {:persist, :created}}}",
         %{automation: automation} do
      assert {:ok, %{automation | new: false}, {:continue, {:persist, :created}}} ==
               Handler.init(automation)
    end

    test "should notify about automation creation", %{
      automation_created: %{automation: automation} = automation_created
    } do
      assert {:noreply, %{automation | new: false}} ==
               Handler.handle_continue(:created, automation)

      assert_receive ^automation_created
    end
  end

  describe "loading process" do
    @describetag :unit

    test "init(%{new: false} = automation) should return {:ok, automation, {:continue, :loaded}}",
         %{
           automation: automation
         } do
      automation = %{automation | new: false}
      assert {:ok, automation, {:continue, :loaded}} == Handler.init(automation)
    end

    test "should notify that automation loaded and try to activate", %{automation: automation} do
      assert {:noreply, automation, {:continue, :maybe_activate}} ==
               Handler.handle_continue(:loaded, automation)

      event =
        [automation_uuid: automation.uuid, automation: automation]
        |> Event.Loaded.new()

      assert_receive ^event
    end

    test "should return {:noreply, automation, {:continue, :activated}} if automation :active is true",
         %{automation: automation} do
      automation = %{automation | active: true}

      assert {:noreply, automation, {:continue, :activated}} ==
               Handler.handle_continue(:maybe_activate, automation)
    end

    test "should return {:noreply, automation} if automation :active is false", %{
      automation: automation
    } do
      automation = %{automation | active: false}

      assert {:noreply, automation} ==
               Handler.handle_continue(:maybe_activate, automation)
    end
  end

  describe "rename: " do
    @describetag :unit

    test "handle_call({:rename, new_name}, automation) should return {:reply, :ok, %{automation | name: new_name}, {:continue, {:persist, :renamed}}}",
         %{automation_created: %{automation: automation}} do
      new_name = Faker.Lorem.word()

      assert {:reply, :ok, %{automation | name: new_name}, {:continue, {:persist, :renamed}}} ==
               Handler.handle_call({:rename, new_name}, self(), automation)

      refute_receive _, 10
    end

    test "handle_continue(:renamed, automation)",
         %{automation_created: %{automation: automation}} do
      assert {:noreply, automation} = Handler.handle_continue(:renamed, automation)

      renamed = Event.Renamed.new(automation_uuid: automation.uuid, name: automation.name)

      assert_receive ^renamed
    end

    test "handle_call({:rename, name}, %{name: name} = automation) should return {:reply, :ok, automation}",
         %{automation_created: %{automation: %{name: name} = automation}} do
      assert {:reply, :ok, automation} ==
               Handler.handle_call({:rename, name}, self(), automation)

      refute_receive _, 10
    end
  end

  describe "activate and basic automation process" do
    @describetag :unit

    test "should reply :ok without :continue if automation already active",
         %{automation_created: %{automation: automation}} do
      assert {:reply, :ok, %{automation | active: true}} ==
               Handler.handle_call(:activate, self(), %{automation | active: true})

      refute_receive _, 10
    end

    test "should set automation :active to true and return {:reply, :ok, {:continue, {:persist, :activated}}}",
         %{automation_created: %{automation: automation}} do
      assert {
               :reply,
               :ok,
               %{automation | active: true},
               {:continue, {:persist, :activated}}
             } == Handler.handle_call(:activate, self(), automation)

      refute_receive _, 10
    end

    test "should reset :last_step_index to -1 and continue with :next_step ",
         %{automation_created: %{automation: automation}} do
      assert {
               :noreply,
               %{automation | last_step_index: -1},
               {:continue, :next_step}
             } == Handler.handle_continue(:activated, %{automation | last_step_index: 5})

      event = Event.Activated.new(automation_uuid: automation.uuid)

      assert_receive ^event
    end
  end

  describe "deactivate" do
    @describetag :unit

    test "should reply :ok without :continue if automation already inactive",
         %{automation_created: %{automation: automation}} do
      assert {:reply, :ok, automation} ==
               Handler.handle_call(:deactivate, self(), automation)

      refute_receive _, 10
    end

    test "should deactivate automation, reply :ok and {:continue, {:persist, :deactivated}}",
         %{automation_created: %{automation: automation}} do
      assert {:reply, :ok, automation, {:continue, {:persist, :deactivated}}} ==
               Handler.handle_call(:deactivate, self(), %{automation | active: true})

      refute_receive _, 10
    end

    test "with {:continue, :deactivated} should fire a Deactivated event",
         %{automation_created: %{automation: automation}} do
      automation = %{automation | steps: [new_step_struct()], last_step_index: 0}

      assert {:noreply, automation} ==
               Handler.handle_continue(:deactivated, automation)

      event = Event.Deactivated.new(automation_uuid: automation.uuid)

      assert_receive ^event
    end

    test "with {:continue, :deactivated} should finish current step",
         %{automation_created: %{automation: automation}} do
      automation = %{automation | steps: [new_step_struct()], last_step_index: 0}

      assert {:noreply, automation} ==
               Handler.handle_continue(:deactivated, automation)

      assert_receive %Event.StepStopped{}
    end

    test "with {:continue, :deactivated} should stop and nilify timer and timer_ref",
         %{automation_created: %{automation: automation}} do
      timer = Process.send_after(self(), :ok, 1_000)
      timer_ref = UUID.uuid4()

      automation = %{
        automation
        | steps: [new_step_struct()],
          last_step_index: 0,
          timer: timer,
          timer_ref: timer_ref
      }

      assert {:noreply, %{automation | timer: nil, timer_ref: nil}} ==
               Handler.handle_continue(:deactivated, automation)

      refute Process.read_timer(timer)
    end
  end

  describe "add step at: " do
    @describetag :unit

    test "{{:add_step_at, step, position}, automation} should add a given step at the requested position, increase :total_steps and {:continue, {:persist, {:step_added_at, step, index}}}",
         %{
           automation: automation
         } do
      # step 1

      {s1, s2, s3, s4} =
        {new_step_struct(), new_step_struct(), new_step_struct(), new_step_struct()}

      steps = [
        {s1, :first, 0, [s1]},
        {s2, 1, 0, [s2, s1]},
        {s3, :last, -1, [s2, s1, s3]},
        {s4, 2, 1, [s2, s4, s1, s3]}
      ]

      steps
      |> Enum.reduce(
        automation,
        fn {%{uuid: step_uuid} = step, position, index, steps},
           %{total_steps: total_steps} = automation ->
          assert {:reply, {:ok, ^step_uuid}, new_automation,
                  {:continue, {:persist, {:step_added_at, ^step, ^index}}}} =
                   Handler.handle_call({:add_step_at, step, position}, self(), automation)

          assert %{automation | steps: steps, total_steps: total_steps + 1} == new_automation

          refute_receive _, 10

          new_automation
        end
      )
    end

    test "handle_continue({:step_added_at, step, index}, automation) should fire StepAddedAt event and return {:noreply, automation}",
         %{
           automation: automation
         } do
      step = new_step_struct()
      index = -1

      step_added_at =
        Event.StepAddedAt.new(automation_uuid: automation.uuid, step: step, index: index)

      assert {:noreply, automation} ==
               Handler.handle_continue({:step_added_at, step, index}, automation)

      assert_receive ^step_added_at
    end

    test "should return {:error, :active_automation_cannot_be_altered}", %{
      automation: %{uuid: uuid} = automation
    } do
      automation = %{automation | active: true}

      step = new_step() |> Step.new()
      position = :first

      step_added_at = Event.StepAddedAt.new(automation_uuid: uuid, step: step, index: 0)

      assert {:reply, {:error, :active_automation_cannot_be_altered}, automation} ==
               Handler.handle_call({:add_step_at, step, position}, self(), automation)

      refute_receive ^step_added_at, 10
    end
  end

  describe "delete step" do
    @describetag :unit

    test "should delete a step with given id and persist", %{
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

        assert {:reply, :ok, %{automation | steps: new_steps, total_steps: new_total_steps},
                {:continue, {:persist, {:step_deleted, step_uuid}}}} ==
                 Handler.handle_call({:delete_step, step_uuid}, self(), %{
                   automation
                   | steps: steps,
                     total_steps: total_steps
                 })

        refute_receive _, 10

        new_steps
      end)
    end

    test "handle_continue({:step_deleted, step_uuid}, automation) should fire event and return {:noreply, automation}",
         %{
           automation: automation
         } do
      step_uuid = UUID.uuid4()

      step_deleted = Event.StepDeleted.new(automation_uuid: automation.uuid, step_uuid: step_uuid)

      assert {:noreply, automation} ==
               Handler.handle_continue({:step_deleted, step_uuid}, automation)

      assert_receive ^step_deleted
    end

    test "should return :ok even if step with given id doesn't exist but no any notifications",
         %{
           automation: automation
         } do
      step_uuid = UUID.uuid4()

      assert {:reply, :ok, automation} ==
               Handler.handle_call({:delete_step, step_uuid}, self(), automation)

      refute_receive _, 10
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

      refute_receive ^step_deleted, 10
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

      assert {:reply, :ok, new_automation,
              {:continue, {:persist, {:step_renamed, step.uuid, new_name}}}} ==
               Handler.handle_call({:rename_step, step.uuid, new_name}, self(), automation)

      refute_receive _, 10
    end

    test "handle_continue({:step_renamed, step_uuid, new_name}, automation) should fire event and return {:noreply, automation}",
         %{
           automation: automation
         } do
      step_uuid = UUID.uuid4()
      new_name = Faker.Lorem.word()

      step_renamed =
        Event.StepRenamed.new(
          automation_uuid: automation.uuid,
          step_uuid: step_uuid,
          name: new_name
        )

      assert {:noreply, automation} ==
               Handler.handle_continue({:step_renamed, step_uuid, new_name}, automation)

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

      refute_receive ^step_renamed, 10
    end

    test "should return {:error, :no_such_step_exists} step with given id doesn't exist but no any notifications",
         %{
           automation: automation
         } do
      step_uuid = UUID.uuid4()
      new_name = new_word()

      assert {:reply, {:error, :no_such_step_exists}, automation} ==
               Handler.handle_call({:rename_step, step_uuid, new_name}, self(), automation)

      refute_receive _, 10
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

      refute_receive ^step_deleted, 10
    end
  end

  describe "move step to" do
    @describetag :unit

    test "should move a step with given id to the given position", %{
      automation: automation
    } do
      initial = [s1, s2, s3, s4] = Enum.map(0..3, fn _ -> new_step_struct() end)

      [
        {s2, :first, 0, [s2, s1, s3, s4]},
        {s1, :last, -1, [s2, s3, s4, s1]},
        {s1, 1, 0, [s1, s2, s3, s4]},
        {s2, 3, 2, [s1, s3, s2, s4]}
      ]
      |> Enum.reduce(initial, fn {step, position, index, final}, initial ->
        assert {:reply, :ok, %{automation | steps: final},
                {:continue, {:persist, {:step_moved_to, step.uuid, index}}}} ==
                 Handler.handle_call(
                   {:move_step_to, step.uuid, position},
                   self(),
                   %{automation | steps: initial}
                 )

        refute_receive _, 10

        final
      end)
    end

    test "handle_continue({:step_moved_to, step_uuid, index}, automation) should fire event and return {:noreply, automation}",
         %{
           automation: automation
         } do
      step_uuid = UUID.uuid4()
      index = Faker.random_between(0, 10)

      step_moved_to =
        Event.StepMovedTo.new(
          automation_uuid: automation.uuid,
          step_uuid: step_uuid,
          index: index
        )

      assert {:noreply, automation} ==
               Handler.handle_continue({:step_moved_to, step_uuid, index}, automation)

      assert_receive ^step_moved_to
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

      refute_receive _, 10
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

      refute_receive _, 10
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

      refute_receive _, 10
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

      assert {:reply, :ok, new_automation, {:continue, {:persist, {:step_activated, step.uuid}}}} ==
               Handler.handle_call({:activate_step, step.uuid}, self(), automation)

      refute_receive _, 10
    end

    test "handle_continue({:step_activated, step_uuid}, automation) should fire event and return {:noreply, automation}",
         %{
           automation: automation
         } do
      step_uuid = UUID.uuid4()

      step_activated =
        Event.StepActivated.new(
          automation_uuid: automation.uuid,
          step_uuid: step_uuid
        )

      assert {:noreply, automation} ==
               Handler.handle_continue({:step_activated, step_uuid}, automation)

      assert_receive ^step_activated
    end

    test "should return :ok if a step with given id already activated", %{
      automation: automation
    } do
      step = new_step(active: true) |> Step.new()

      automation = %{automation | steps: [step]}

      assert {:reply, :ok, automation} ==
               Handler.handle_call({:activate_step, step.uuid}, self(), automation)

      refute_receive _, 10
    end

    test "should return {:error, :no_such_step_exists} step with given id doesn't exist but no any notifications",
         %{
           automation: automation
         } do
      step_uuid = UUID.uuid4()

      assert {:reply, {:error, :no_such_step_exists}, automation} ==
               Handler.handle_call({:activate_step, step_uuid}, self(), automation)

      refute_receive _, 10
    end

    test "should return {:error, :active_automation_cannot_be_altered}", %{
      automation: automation
    } do
      # step 1

      step = new_step_struct()

      automation = %{automation | active: true, steps: [step]}

      assert {:reply, {:error, :active_automation_cannot_be_altered}, automation} ==
               Handler.handle_call({:activate_step, step.uuid}, self(), automation)

      refute_receive _, 10
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

      assert {:reply, :ok, new_automation,
              {:continue, {:persist, {:step_deactivated, step.uuid}}}} ==
               Handler.handle_call({:deactivate_step, step.uuid}, self(), automation)

      refute_receive _, 10
    end

    test "handle_continue({:step_deactivated, step_uuid}, automation) should fire event and return {:noreply, automation}",
         %{
           automation: automation
         } do
      step_uuid = UUID.uuid4()

      step_deactivated =
        Event.StepDeactivated.new(
          automation_uuid: automation.uuid,
          step_uuid: step_uuid
        )

      assert {:noreply, automation} ==
               Handler.handle_continue({:step_deactivated, step_uuid}, automation)

      assert_receive ^step_deactivated
    end

    test "should return :ok if a step with given id already deactivated", %{
      automation: automation
    } do
      step = new_step() |> Step.new()

      automation = %{automation | steps: [step]}

      assert {:reply, :ok, automation} ==
               Handler.handle_call({:deactivate_step, step.uuid}, self(), automation)

      refute_receive _, 10
    end

    test "should return {:error, :no_such_step_exists} step with given id doesn't exist but no any notifications",
         %{
           automation: automation
         } do
      step_uuid = UUID.uuid4()

      assert {:reply, {:error, :no_such_step_exists}, automation} ==
               Handler.handle_call({:deactivate_step, step_uuid}, self(), automation)

      refute_receive _, 10
    end

    test "should return {:error, :active_automation_cannot_be_altered}", %{
      automation: automation
    } do
      # step 1

      step = new_step_struct(active: true)

      automation = %{automation | active: true, steps: [step]}

      assert {:reply, {:error, :active_automation_cannot_be_altered}, automation} ==
               Handler.handle_call({:deactivate_step, step.uuid}, self(), automation)

      refute_receive _, 10
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
