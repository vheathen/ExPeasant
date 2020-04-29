defmodule Peasant.Storage.ObserverTest do
  use Peasant.GeneralCase

  alias Peasant.Storage.Keeper

  alias Peasant.Tools.FakeTool

  alias Peasant.Tool.Event, as: Tool

  alias Peasant.Automation.Event, as: Automation

  alias Peasant.Storage.Observer

  @observer Peasant.Storage.Observer
  @tools "tools"
  @automations "automations"

  setup do
    Peasant.subscribe(@tools)
    Peasant.subscribe(@automations)

    assert is_pid(GenServer.whereis(@observer))

    [db: Keeper.db()]
  end

  describe "Observer" do
    @describetag :integration

    test "should be started", do: :ok
  end

  ############# Tools ###########################

  describe "on Tool.Registered event" do
    @describetag :integration

    setup :tool_registered_setup

    test "should persist a tool record on Registered event", %{
      tool: %type{uuid: uuid},
      db: db
    } do
      assert {@tools, %^type{uuid: ^uuid}} = CubDB.get(db, uuid)
      assert true == CubDB.get(db, {@tools, type, uuid})
    end
  end

  describe "on Tool.Attached event" do
    @describetag :integration

    setup [:tool_registered_setup, :tool_attached_setup]

    test "should persist a tool record on Attached event", %{
      tool: %{uuid: uuid},
      db: db
    } do
      assert {@tools, %{uuid: ^uuid, attached: true}} = CubDB.get(db, uuid)
    end
  end

  def tool_registered_setup(%{db: db}) do
    %type{uuid: uuid} = tool = new_tool() |> FakeTool.new() |> Map.put(:new, false)
    event = Tool.Registered.new(tool_uuid: tool.uuid, details: %{tool: tool})

    assert is_nil(CubDB.get(db, uuid))
    assert is_nil(CubDB.get(db, {@tools, type, uuid}))

    notify(event, @tools)
    Process.sleep(100)

    assert_received ^event

    [tool: tool]
  end

  def tool_attached_setup(%{tool: %{uuid: uuid}}) do
    event = Tool.Attached.new(tool_uuid: uuid)

    notify(event, @tools)
    Process.sleep(100)

    assert_received ^event

    :ok
  end

  ############# Automation ###########################

  describe "on Automation.Created event" do
    @describetag :integration

    setup :automation_created_setup

    test "should persist an automation record", %{
      automation: %{uuid: uuid},
      db: db
    } do
      assert {@automations, %{uuid: ^uuid}} = CubDB.get(db, uuid)
      assert true == CubDB.get(db, {@automations, Peasant.Automation.State, uuid})
    end
  end

  describe "on Automation.Activated event" do
    @describetag :integration

    setup [:automation_created_setup, :automation_activated_setup]

    test "should persist an automation record", %{
      automation: %{uuid: uuid},
      db: db
    } do
      assert {@automations, %{uuid: ^uuid, active: true}} = CubDB.get(db, uuid)
    end
  end

  describe "on Automation.Dectivated event" do
    @describetag :integration

    setup [:automation_created_setup, :automation_activated_setup, :automation_deactivated_setup]

    test "should persist an automation record", %{
      automation: %{uuid: uuid},
      db: db
    } do
      assert {@automations, %{uuid: ^uuid, active: false}} = CubDB.get(db, uuid)
    end
  end

  describe "on Automation.Renamed event" do
    @describetag :integration

    setup [:automation_created_setup, :automation_rename_setup]

    test "should persist an automation record", %{
      automation: %{uuid: uuid},
      new_name: name,
      db: db
    } do
      assert {@automations, %{uuid: ^uuid, name: ^name}} = CubDB.get(db, uuid)
    end
  end

  describe "on Automation.StepAddedAt event" do
    @describetag :integration

    setup [:automation_created_setup, :automation_step_added_at_setup]

    test "should persist an automation record", %{
      automation: %{uuid: uuid},
      steps: steps,
      db: db
    } do
      assert {@automations, %{uuid: ^uuid, steps: ^steps}} = CubDB.get(db, uuid)
    end
  end

  describe "on Automation.StepDeleted event" do
    @describetag :integration

    setup [
      :automation_created_setup,
      :automation_step_added_at_setup,
      :automation_step_deleted_setup
    ]

    test "should persist an automation record", %{
      automation: %{uuid: uuid},
      steps: steps,
      db: db
    } do
      assert {@automations, %{uuid: ^uuid, steps: ^steps}} = CubDB.get(db, uuid)
    end
  end

  describe "on Automation.StepRenamed event" do
    @describetag :integration

    setup [
      :automation_created_setup,
      :automation_step_added_at_setup,
      :automation_step_renamed_setup
    ]

    test "should persist an automation record", %{
      automation: %{uuid: uuid},
      steps: steps,
      db: db
    } do
      assert {@automations, %{uuid: ^uuid, steps: ^steps}} = CubDB.get(db, uuid)
    end
  end

  describe "on Automation.StepMovedTo event" do
    @describetag :integration

    setup [
      :automation_created_setup,
      :automation_step_added_at_setup,
      :automation_step_moved_to_setup
    ]

    test "should persist an automation record", %{
      automation: %{uuid: uuid},
      steps: steps,
      db: db
    } do
      assert {@automations, %{uuid: ^uuid, steps: ^steps}} = CubDB.get(db, uuid)
    end
  end

  describe "on Automation.StepActivated event" do
    @describetag :integration

    setup [
      :automation_created_setup,
      :automation_step_added_at_setup,
      :automation_step_activated_setup
    ]

    test "should persist an automation record", %{
      automation: %{uuid: uuid},
      steps: steps,
      db: db
    } do
      assert {@automations, %{uuid: ^uuid, steps: ^steps}} = CubDB.get(db, uuid)
    end
  end

  describe "on Automation.StepDeactivated event" do
    @describetag :integration

    setup [
      :automation_created_setup,
      :automation_step_added_at_setup,
      :automation_step_activated_setup,
      :automation_step_deactivated_setup
    ]

    test "should persist an automation record", %{
      automation: %{uuid: uuid},
      steps: steps,
      db: db
    } do
      assert {@automations, %{uuid: ^uuid, steps: ^steps}} = CubDB.get(db, uuid)
    end
  end

  def automation_created_setup(%{db: db}) do
    %{uuid: uuid} =
      automation = new_automation() |> Peasant.Automation.State.new() |> Map.put(:new, false)

    event = Automation.Created.new(automation_uuid: automation.uuid, automation: automation)

    assert is_nil(CubDB.get(db, uuid))
    assert is_nil(CubDB.get(db, {@automations, Peasant.Automation.State, uuid}))

    notify(event, @automations)

    Process.sleep(100)

    assert_received ^event

    [automation: automation]
  end

  def automation_rename_setup(%{automation: %{uuid: uuid, name: name}, db: db}) do
    new_name = unique_word(name)
    assert {@automations, %{uuid: ^uuid, name: name}} = CubDB.get(db, uuid)
    event = Automation.Renamed.new(automation_uuid: uuid, name: new_name)
    notify(event, @automations)
    Process.sleep(100)
    assert_received ^event

    [new_name: new_name]
  end

  def automation_activated_setup(%{automation: %{uuid: uuid}, db: db}) do
    assert {@automations, %{uuid: ^uuid, active: false}} = CubDB.get(db, uuid)
    event = Automation.Activated.new(automation_uuid: uuid)
    notify(event, @automations)
    Process.sleep(100)
    assert_received ^event

    :ok
  end

  def automation_deactivated_setup(%{automation: %{uuid: uuid}, db: db}) do
    assert {@automations, %{uuid: ^uuid, active: true}} = CubDB.get(db, uuid)
    event = Automation.Deactivated.new(automation_uuid: uuid)
    notify(event, @automations)
    Process.sleep(100)
    assert_received ^event

    :ok
  end

  def automation_step_added_at_setup(%{automation: %{uuid: uuid}, db: db}) do
    assert {@automations, %{uuid: ^uuid, steps: []}} = CubDB.get(db, uuid)

    steps =
      1..Faker.random_between(5, 10)
      |> Enum.map(fn _ ->
        event =
          [automation_uuid: uuid, step: new_step_struct(), index: -1]
          |> Automation.StepAddedAt.new()

        notify(event, @automations)
        assert_received ^event

        event.step
      end)

    Process.sleep(100)

    [steps: steps]
  end

  def automation_step_activated_setup(%{automation: %{uuid: uuid}, steps: steps}) do
    random_step_index = Enum.random(0..(length(steps) - 1))

    _random_step = %{uuid: step_uuid, active: false} = Enum.at(steps, random_step_index)

    event =
      [automation_uuid: uuid, step_uuid: step_uuid]
      |> Automation.StepActivated.new()

    notify(event, @automations)
    assert_received ^event

    Process.sleep(100)

    steps = List.update_at(steps, random_step_index, &%{&1 | active: true})

    [steps: steps]
  end

  def automation_step_deactivated_setup(%{automation: %{uuid: uuid}, steps: steps}) do
    active_step_index = Enum.find_index(steps, &(&1.active == true))

    _active_step = %{uuid: step_uuid, active: true} = Enum.at(steps, active_step_index)

    event =
      [automation_uuid: uuid, step_uuid: step_uuid]
      |> Automation.StepDeactivated.new()

    notify(event, @automations)
    assert_received ^event

    Process.sleep(100)

    steps = List.update_at(steps, active_step_index, &%{&1 | active: false})

    [steps: steps]
  end

  def automation_step_deleted_setup(%{automation: %{uuid: uuid}, steps: steps}) do
    random_step_index = Enum.random(0..(length(steps) - 1))

    _random_step = %{uuid: step_uuid} = Enum.at(steps, random_step_index)

    event =
      [automation_uuid: uuid, step_uuid: step_uuid]
      |> Automation.StepDeleted.new()

    notify(event, @automations)
    assert_received ^event

    Process.sleep(100)

    steps = List.delete_at(steps, random_step_index)

    [steps: steps]
  end

  def automation_step_renamed_setup(%{automation: %{uuid: uuid}, steps: steps}) do
    random_step_index = Enum.random(0..(length(steps) - 1))

    _random_step = %{uuid: step_uuid, name: name} = Enum.at(steps, random_step_index)

    new_name = unique_word(name)

    event =
      [automation_uuid: uuid, step_uuid: step_uuid, name: new_name]
      |> Automation.StepRenamed.new()

    notify(event, @automations)
    assert_received ^event

    Process.sleep(100)

    steps = List.update_at(steps, random_step_index, &%{&1 | name: new_name})

    [steps: steps]
  end

  def automation_step_moved_to_setup(%{automation: %{uuid: uuid}, steps: steps}) do
    random_step = %{uuid: step_uuid} = Enum.random(steps)
    random_index = Enum.random(0..(length(steps) - 1))

    event =
      [automation_uuid: uuid, step_uuid: step_uuid, index: random_index]
      |> Automation.StepMovedTo.new()

    notify(event, @automations)
    assert_received ^event

    Process.sleep(100)

    steps =
      steps
      |> List.delete(random_step)
      |> List.insert_at(random_index, random_step)

    [steps: steps]
  end

  ############# Common ###########################

  describe "list(domain) function" do
    @describetag :integration

    setup :list_setup

    test "should list all objects for the specified domain", %{
      tools: tools,
      automations: automations
    } do
      assert tools == Observer.list(@tools) |> nilify_timestamps() |> Enum.sort()
      assert automations == Observer.list(@automations) |> nilify_timestamps() |> Enum.sort()
    end
  end

  describe "get(id, domain) function" do
    @describetag :integration

    setup :list_setup

    test "should return an object with a given id from a specified domain", %{
      tools: tools,
      automations: automations
    } do
      Enum.each(tools, fn %{uuid: uuid} = tool ->
        assert tool == Observer.get(uuid, @tools) |> nilify_timestamps()
      end)

      Enum.each(automations, fn %{uuid: uuid} = automation ->
        assert automation == Observer.get(uuid, @automations) |> nilify_timestamps()
      end)
    end
  end

  describe "clear/1" do
    @describetag :integration

    test "should clear all records on domain" do
      :ok = Observer.clear(@tools)
      assert [] == Observer.list(@tools)

      :ok = Observer.clear(@automations)
      assert [] == Observer.list(@automations)
    end
  end

  describe "on start" do
    @describetag :integration

    setup :list_setup

    test "it should load all records", %{tools: tools, automations: automations} do
      assert tools == Observer.list(@tools) |> nilify_timestamps() |> Enum.sort()
      assert automations == Observer.list(@automations) |> nilify_timestamps() |> Enum.sort()
    end

    test "it should populate all tools", %{tools: tools} do
      Enum.each(tools, fn %{uuid: uuid} ->
        assert [{pid, nil}] = Registry.lookup(Peasant.Registry, uuid)

        assert is_pid(pid)
      end)
    end

    test "it should populate all automations", %{automations: automations} do
      Enum.each(automations, fn %{uuid: uuid} ->
        assert [{pid, nil}] = Registry.lookup(Peasant.Registry, uuid)

        assert is_pid(pid)
      end)
    end
  end

  def list_setup(context) do
    [tool: tool1] = tool_registered_setup(context)
    [tool: tool2] = tool_registered_setup(context)
    tools = [tool1, tool2] |> Enum.sort()
    assert tools == Observer.list(@tools) |> nilify_timestamps() |> Enum.sort()

    [automation: automation1] = automation_created_setup(context)
    [automation: automation2] = automation_created_setup(context)
    automations = [automation1, automation2] |> Enum.sort()
    assert automations == Observer.list(@automations) |> nilify_timestamps() |> Enum.sort()

    :ok = GenServer.stop(Observer)

    start_supervised(Observer)

    Process.sleep(100)

    [tools: tools, automations: automations]
  end

  defp notify(event, domain), do: Peasant.broadcast(domain, event)

  defp nilify_timestamps(records) when is_list(records),
    do: Enum.map(records, &nilify_timestamps/1)

  defp nilify_timestamps(record), do: %{record | inserted_at: nil, updated_at: nil}
end
