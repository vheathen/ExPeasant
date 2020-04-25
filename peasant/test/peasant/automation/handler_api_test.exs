defmodule Peasant.Automation.HandlerAPITest do
  use Peasant.DataCase

  alias Peasant.Automation.State
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
      assert [{pid, nil}] = Registry.lookup(Peasant.Registry, uuid)
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

  def automation_setup(_context) do
    automation = new_automation() |> State.new()

    [automation: automation]
  end
end
