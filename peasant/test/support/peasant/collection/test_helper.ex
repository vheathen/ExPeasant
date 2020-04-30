defmodule Peasant.Collection.TestHelper do
  use ExUnit.CaseTemplate

  # import Peasant.Factory
  import Peasant.Fixture
  import Peasant.TestHelper

  alias Peasant.Repo

  alias Peasant.Tools.FakeTool

  alias Peasant.Tool.Event, as: Tool

  alias Peasant.Automation.Event, as: Automation

  @db Peasant.Collection.Keeper

  @tools Peasant.Tool.domain()
  @automations Peasant.Automation.domain()

  def automation_created_setup(_) do
    %{uuid: uuid} =
      automation = new_automation() |> Peasant.Automation.State.new() |> Map.put(:new, false)

    event = Automation.Created.new(automation_uuid: automation.uuid, automation: automation)

    assert is_nil(CubDB.get(@db, uuid))
    assert is_nil(CubDB.get(@db, {@automations, Peasant.Automation.State, uuid}))

    notify(event, @automations)

    # Process.sleep(100)
    :sys.get_state(Peasant.Collection.Observer.Automations)

    assert_received ^event

    [automation: automation]
  end

  def automation_rename_setup(%{automation: %{uuid: uuid, name: name}}) do
    new_name = unique_word(name)
    assert {@automations, %{uuid: ^uuid, name: name}} = CubDB.get(@db, uuid)
    event = Automation.Renamed.new(automation_uuid: uuid, name: new_name)
    notify(event, @automations)

    # Process.sleep(100)
    :sys.get_state(Peasant.Collection.Observer.Automations)

    assert_received ^event

    [new_name: new_name]
  end

  def automation_activated_setup(%{automation: %{uuid: uuid}}) do
    assert {@automations, %{uuid: ^uuid, active: false}} = CubDB.get(@db, uuid)
    event = Automation.Activated.new(automation_uuid: uuid)
    notify(event, @automations)

    # Process.sleep(100)
    :sys.get_state(Peasant.Collection.Observer.Automations)

    assert_received ^event

    :ok
  end

  def automation_deactivated_setup(%{automation: %{uuid: uuid}}) do
    assert {@automations, %{uuid: ^uuid, active: true}} = CubDB.get(@db, uuid)
    event = Automation.Deactivated.new(automation_uuid: uuid)
    notify(event, @automations)

    # Process.sleep(100)

    :sys.get_state(Peasant.Collection.Observer.Automations)

    assert_received ^event

    :ok
  end

  def automation_step_added_at_setup(%{automation: %{uuid: uuid}}) do
    assert {@automations, %{uuid: ^uuid, steps: []}} = CubDB.get(@db, uuid)

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

    # Process.sleep(100)
    :sys.get_state(Peasant.Collection.Observer.Automations)

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

    # Process.sleep(100)
    :sys.get_state(Peasant.Collection.Observer.Automations)

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

    # Process.sleep(100)
    :sys.get_state(Peasant.Collection.Observer.Automations)

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

    # Process.sleep(100)
    :sys.get_state(Peasant.Collection.Observer.Automations)

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

    # Process.sleep(100)
    :sys.get_state(Peasant.Collection.Observer.Automations)

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

    # Process.sleep(100)
    :sys.get_state(Peasant.Collection.Observer.Automations)

    steps =
      steps
      |> List.delete(random_step)
      |> List.insert_at(random_index, random_step)

    [steps: steps]
  end

  #################
  ################# Tools
  #################

  def tool_registered_setup(_) do
    %type{uuid: uuid} = tool = new_tool() |> FakeTool.new() |> Map.put(:new, false)
    event = Tool.Registered.new(tool_uuid: tool.uuid, details: %{tool: tool})

    assert is_nil(CubDB.get(@db, uuid))
    assert is_nil(CubDB.get(@db, {@tools, type, uuid}))

    Peasant.broadcast(@tools, event)
    # Process.sleep(100)
    :sys.get_state(Peasant.Collection.Observer.Tools)

    assert_received ^event

    [tool: tool]
  end

  def tool_attached_setup(%{tool: %{uuid: uuid}}) do
    event = Tool.Attached.new(tool_uuid: uuid)

    Peasant.broadcast(@tools, event)

    # Process.sleep(100)

    :sys.get_state(Peasant.Collection.Observer.Tools)

    assert_received ^event

    :ok
  end

  def collection_setup(context) do
    [tool: tool1] = tool_registered_setup(context)
    [tool: tool2] = tool_registered_setup(context)
    tools = [tool1, tool2] |> Enum.sort()
    assert tools == Repo.list(@tools) |> nilify_timestamps() |> Enum.sort()

    [automation: automation1] = automation_created_setup(context)
    [automation: automation2] = automation_created_setup(context)
    automations = [automation1, automation2] |> Enum.sort()
    assert automations == Repo.list(@automations) |> nilify_timestamps() |> Enum.sort()

    [tools: tools, automations: automations]
  end

  def on_start_collection_setup(_context) do
    Repo.clear(@tools)
    Repo.clear(@automations)

    assert [] = Repo.list(@tools)
    assert [] = Repo.list(@automations)

    :ok = GenServer.stop(Peasant.Collection.Observer)
    start_supervised(Peasant.Collection.Observer)

    # Process.sleep(100)
    assert :ready = Peasant.system_state()

    assert length(Repo.list(@tools)) > 0
    assert length(Repo.list(@automations)) > 0

    :ok
  end

  def notify(event, domain), do: Peasant.broadcast(domain, event)

  def nilify_timestamps(records) when is_list(records),
    do: Enum.map(records, &nilify_timestamps/1)

  def nilify_timestamps(record), do: %{record | inserted_at: nil, updated_at: nil}
end
