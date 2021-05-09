defmodule Peasant.Automation.HandlerAPITest do
  use Peasant.GeneralCase

  alias Peasant.Automation.State
  alias Peasant.Automation.State.Step
  alias Peasant.Automation.Handler

  setup do
    uuid = UUID.uuid4()
    spec = %{uuid: uuid, test_pid: self()}

    start_supervised(
      Peasant.Automation.FakeHandler,
      handler_child_spec(Peasant.Automation.FakeHandler, spec)
    )

    [uuid: uuid]
  end

  describe "start_link/1" do
    @describetag :unit

    setup :automation_setup

    test "should start a process with via_tuple name", %{automation: %{uuid: uuid} = automation} do
      assert {:ok, pid} = Handler.start_link(automation)
      assert is_pid(pid)
      assert [{^pid, nil}] = Registry.lookup(Peasant.Registry, uuid)
    end
  end

  describe "create/1" do
    @describetag :integration

    setup :automation_setup

    setup %{automation: automation} do
      assert {:ok, pid} = Handler.create(automation)
      [pid: pid]
    end

    test "should start a handler process via Toolbox supervisor", %{pid: pid} do
      assert {:undefined, pid, :worker, [Handler]} in DynamicSupervisor.which_children(
               Peasant.ActivityMaster
             )
    end
  end

  describe "rename/2" do
    @describetag :unit

    test "should cast {:rename, new_name} to a process with uuid as id", %{uuid: uuid} do
      new_name = Faker.Lorem.word()

      assert {:call, {:rename, new_name}} ==
               Handler.rename(uuid, new_name)
    end

    test "should return {:error, :no_automation_exists} for an unknown uuid" do
      new_name = Faker.Lorem.word()
      uuid = UUID.uuid4()

      assert {:error, :no_automation_exists} ==
               Handler.rename(uuid, new_name)
    end
  end

  describe "activate/2" do
    @describetag :unit

    test "should cast :activate to a process with uuid as id", %{uuid: uuid} do
      assert {:call, :activate} == Handler.activate(uuid)
    end

    test "should return {:error, :no_automation_exists} for an unknown uuid" do
      uuid = UUID.uuid4()

      assert {:error, :no_automation_exists} == Handler.activate(uuid)
    end
  end

  describe "deactivate/2" do
    @describetag :unit

    test "should cast :deactivate to a process with uuid as id", %{uuid: uuid} do
      assert {:call, :deactivate} == Handler.deactivate(uuid)
    end

    test "should return {:error, :no_automation_exists} for an unknown uuid" do
      uuid = UUID.uuid4()

      assert {:error, :no_automation_exists} == Handler.deactivate(uuid)
    end
  end

  describe "add_step_at/3" do
    @describetag :unit

    test "should cast {:add_step_at, step, position} to a process with uuid as id", %{uuid: uuid} do
      step = new_step() |> Step.new()
      position = :first

      assert {:call, {:add_step_at, step, position}} ==
               Handler.add_step_at(uuid, step, position)
    end

    test "should return {:error, :no_automation_exists} for an unknown uuid" do
      step = new_step() |> Step.new()
      position = :first
      uuid = UUID.uuid4()

      assert {:error, :no_automation_exists} ==
               Handler.add_step_at(uuid, step, position)
    end
  end

  describe "delete_step/2" do
    @describetag :unit

    test "should cast {:delete_step, step_uuid} to a process with uuid as id", %{
      uuid: automation_uuid
    } do
      step_uuid = UUID.uuid4()

      assert {:call, {:delete_step, step_uuid}} ==
               Handler.delete_step(automation_uuid, step_uuid)
    end

    test "should return {:error, :no_automation_exists} for an unknown uuid" do
      step_uuid = UUID.uuid4()
      automation_uuid = UUID.uuid4()

      assert {:error, :no_automation_exists} ==
               Handler.delete_step(automation_uuid, step_uuid)
    end
  end

  describe "change_step_description/3" do
    @describetag :unit

    test "should cast {:change_step_description, step_uuid, new_description} to a process with uuid as id",
         %{
           uuid: automation_uuid
         } do
      step_uuid = UUID.uuid4()
      new_description = Faker.Lorem.sentence()

      assert {:call, {:change_step_description, step_uuid, new_description}} ==
               Handler.change_step_description(automation_uuid, step_uuid, new_description)
    end

    test "should return {:error, :no_automation_exists} for an unknown uuid" do
      step_uuid = UUID.uuid4()
      automation_uuid = UUID.uuid4()
      new_description = Faker.Lorem.sentence()

      assert {:error, :no_automation_exists} ==
               Handler.change_step_description(automation_uuid, step_uuid, new_description)
    end
  end

  describe "move_step_to/3" do
    @describetag :unit

    test "should cast {:move_step_to, step_uuid, position} to a process with uuid as id", %{
      uuid: automation_uuid
    } do
      step_uuid = UUID.uuid4()
      position = :last

      assert {:call, {:move_step_to, step_uuid, position}} ==
               Handler.move_step_to(automation_uuid, step_uuid, position)
    end

    test "should return {:error, :no_automation_exists} for an unknown uuid" do
      step_uuid = UUID.uuid4()
      automation_uuid = UUID.uuid4()
      position = :last

      assert {:error, :no_automation_exists} ==
               Handler.move_step_to(automation_uuid, step_uuid, position)
    end
  end

  describe "activate_step/2" do
    @describetag :unit

    test "should cast {:activate_step, step_uuid} to a process with uuid as id", %{
      uuid: automation_uuid
    } do
      step_uuid = UUID.uuid4()

      assert {:call, {:activate_step, step_uuid}} ==
               Handler.activate_step(automation_uuid, step_uuid)
    end

    test "should return {:error, :no_automation_exists} for an unknown uuid" do
      step_uuid = UUID.uuid4()
      automation_uuid = UUID.uuid4()

      assert {:error, :no_automation_exists} ==
               Handler.activate_step(automation_uuid, step_uuid)
    end
  end

  describe "deactivate_step/2" do
    @describetag :unit

    test "should cast {:deactivate_step, step_uuid} to a process with uuid as id", %{
      uuid: automation_uuid
    } do
      step_uuid = UUID.uuid4()

      assert {:call, {:deactivate_step, step_uuid}} ==
               Handler.deactivate_step(automation_uuid, step_uuid)
    end

    test "should return {:error, :no_automation_exists} for an unknown uuid" do
      step_uuid = UUID.uuid4()
      automation_uuid = UUID.uuid4()

      assert {:error, :no_automation_exists} ==
               Handler.deactivate_step(automation_uuid, step_uuid)
    end
  end

  def automation_setup(_context) do
    automation = new_automation() |> State.new()

    [automation: automation]
  end
end
