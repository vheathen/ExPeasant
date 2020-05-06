defmodule Peasant.AutomationTest do
  use Peasant.GeneralCase

  alias Peasant.Automation

  alias Peasant.Automation.State
  alias Peasant.Automation.State.Step

  setup_all do
    automation_handler = Application.get_env(:peasant, :automation_handler)
    Application.put_env(:peasant, :automation_handler, Peasant.Automation.FakeHandler)

    on_exit(fn ->
      Application.put_env(:peasant, :automation_handler, automation_handler)
    end)
  end

  setup do
    automation_spec = new_automation()

    assert %State{} = automation = State.new(automation_spec)

    [automation_spec: automation_spec, automation: automation]
  end

  describe "Automation module" do
    @describetag :unit

    test "should intoduce State struct and functions", do: :ok
  end

  describe "Creation and create/1" do
    @describetag :unit

    test "should return {:ok, uuid} in case of correct automation specs", %{
      automation_spec: automation_spec
    } do
      assert {:ok, uuid} = Automation.create(automation_spec)
      assert is_binary(uuid)
      assert {:ok, _} = UUID.info(uuid)

      assert_receive {:create, %State{uuid: ^uuid}}
    end

    test "should return {:error, error} in case of incorrect automation specs" do
      automation = new_automation() |> Map.delete(:name)
      assert {:error, _} = Automation.create(automation)

      refute_receive {:create, %State{}}, 10
    end
  end

  # describe "delete(automation_uuid)" do
  #   @describetag :unit

  #   test "should run Handler.delete(automation_uuid)", %{automation: %{uuid: uuid}} do
  #     assert :ok = Automation.delete(uuid)
  #     assert_receive {:delete, ^uuid}
  #   end
  # end

  describe "rename/2" do
    @describetag :unit
    test "should run Handler.rename(uuid, new_name)", %{automation: %{uuid: uuid}} do
      new_name = Faker.Lorem.word()
      assert :ok = Automation.rename(uuid, new_name)
      assert_receive {:rename, ^uuid, ^new_name}
    end
  end

  describe "activate/1" do
    @describetag :unit
    test "should run Handler.activate(uuid)", %{automation: %{uuid: uuid}} do
      assert :ok = Automation.activate(uuid)
      assert_receive {:activate, ^uuid}
    end
  end

  describe "deactivate/1" do
    @describetag :unit
    test "should run Handler.deactivate(uuid)", %{automation: %{uuid: uuid}} do
      assert :ok = Automation.deactivate(uuid)
      assert_receive {:deactivate, ^uuid}
    end
  end

  describe "add_step_at/3" do
    @describetag :unit

    test "should run Handler.add_step_at(uuid, step, position) if options are correct", %{
      automation: %{uuid: uuid}
    } do
      step_spec = new_step()
      position = :first

      assert {:ok, step_uuid} = Automation.add_step_at(uuid, step_spec, position)

      step = step_spec |> Step.new() |> Map.put(:uuid, step_uuid)

      assert_receive {:add_step_at, ^uuid, ^step, ^position}
    end

    test "should return {:error, term()} if step specs are incorrect", %{
      automation: %{uuid: uuid}
    } do
      step_spec = %{new_step() | action: "unknown_action_#{UUID.uuid4()}"}
      position = :last

      assert {:error, [action: {"doesn't exist", [validation: :action]}]} =
               Automation.add_step_at(uuid, step_spec, position)

      refute_receive {:add_step_at, ^uuid, _, ^position}, 10
    end

    test "should return {:error, :incorrect_position} if position are incorrect", %{
      automation: %{uuid: uuid}
    } do
      [:atom, Faker.random_between(-10000, 0), 0]
      |> Enum.each(fn position ->
        step_spec = new_step()

        assert {:error, :incorrect_position} = Automation.add_step_at(uuid, step_spec, position)
        refute_receive {:add_step_at, ^uuid, _, ^position}, 10
      end)
    end
  end

  describe "delete_step/2" do
    @describetag :unit
    test "should run Handler.delete_step(automation_uuid, step_uuid)", %{
      automation: %{uuid: automation_uuid}
    } do
      step_uuid = UUID.uuid4()

      assert :ok = Automation.delete_step(automation_uuid, step_uuid)
      assert_receive {:delete_step, ^automation_uuid, ^step_uuid}
    end
  end

  describe "change_step_description/3" do
    @describetag :unit
    test "should run Handler.change_step_description(automation_uuid, step_uuid, new_description)",
         %{
           automation: %{uuid: automation_uuid}
         } do
      step_uuid = UUID.uuid4()
      new_description = Faker.Lorem.sentence()

      assert :ok = Automation.change_step_description(automation_uuid, step_uuid, new_description)
      assert_receive {:change_step_description, ^automation_uuid, ^step_uuid, ^new_description}
    end
  end

  describe "move_step_to/3" do
    @describetag :unit

    test "should run Handler.move_step_to(automation_uuid, step_uuid, position)", %{
      automation: %{uuid: automation_uuid}
    } do
      step_uuid = UUID.uuid4()
      position = :last

      assert :ok = Automation.move_step_to(automation_uuid, step_uuid, position)
      assert_receive {:move_step_to, ^automation_uuid, ^step_uuid, ^position}
    end

    test "should return {:error, :incorrect_position} if position are incorrect", %{
      automation: %{uuid: uuid}
    } do
      [:atom, Faker.random_between(-10000, 0), 0]
      |> Enum.each(fn position ->
        step_uuid = UUID.uuid4()

        assert {:error, :incorrect_position} = Automation.move_step_to(uuid, step_uuid, position)
        refute_receive {:add_step_at, ^uuid, _, ^position}, 10
      end)
    end
  end

  describe "activate_step/3" do
    @describetag :unit
    test "should run Handler.activate_step(automation_uuid, step_uuid)", %{
      automation: %{uuid: automation_uuid}
    } do
      step_uuid = UUID.uuid4()

      assert :ok = Automation.activate_step(automation_uuid, step_uuid)
      assert_receive {:activate_step, ^automation_uuid, ^step_uuid}
    end
  end

  describe "deactivate_step/3" do
    @describetag :unit
    test "should run Handler.deactivate_step(automation_uuid, step_uuid)", %{
      automation: %{uuid: automation_uuid}
    } do
      step_uuid = UUID.uuid4()

      assert :ok = Automation.deactivate_step(automation_uuid, step_uuid)
      assert_receive {:deactivate_step, ^automation_uuid, ^step_uuid}
    end
  end
end
