defmodule Peasant.Collection.Observer.AutomationsTest do
  use Peasant.GeneralCase

  import Peasant.Collection.TestHelper

  alias Peasant.Collection.Keeper

  @observer Peasant.Collection.Observer.Automations

  @automations Peasant.Automation.domain()

  setup do
    Peasant.subscribe(@automations)

    assert is_pid(GenServer.whereis(@observer))

    [db: Keeper.db()]
  end

  describe "Automations Observer" do
    @describetag :integration

    test "should be started", do: :ok
  end

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
end
