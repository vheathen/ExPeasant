defmodule Peasant.Tool.HandlerAPITest do
  use Peasant.GeneralCase

  alias Peasant.Tool.Handler

  alias Peasant.Tools.FakeTool

  defmodule FakeHandler do
    use GenServer

    def start_link(%{uuid: uuid} = spec),
      do: GenServer.start_link(__MODULE__, spec, name: via_tuple(uuid))

    ### GenServer implementation

    @impl true
    def init(%{test_pid: pid} = params) do
      Process.send(pid, {:init, params}, [])
      {:ok, pid}
    end

    @impl true
    def handle_call(params, _from, pid), do: {:reply, {:call, params}, pid}

    @impl true
    def handle_cast(params, pid) do
      Process.send(pid, {:cast, params}, [])
      {:noreply, pid}
    end

    @impl true
    def handle_info(params, pid) do
      Process.send(pid, {:info, params}, [])
      {:noreply, pid}
    end
  end

  setup do
    uuid = UUID.uuid4()

    spec = %{uuid: uuid, test_pid: self()}

    start_supervised(FakeHandler, handler_child_spec(FakeHandler, spec))

    [uuid: uuid]
  end

  describe "start_link/1" do
    @describetag :unit

    setup :fake_tool

    test "should start a process with via_tuple name", %{fake_tool: %{uuid: uuid} = tool} do
      assert {:ok, pid} = Handler.start_link(tool)
      assert is_pid(pid)
      assert [{pid, nil}] = Registry.lookup(Peasant.Registry, uuid)
    end
  end

  describe "register/1" do
    @describetag :integration

    setup :fake_tool

    setup %{fake_tool: tool} do
      assert {:ok, pid} = Handler.register(tool)
      [tool: tool, pid: pid]
    end

    test "should start a handler process via Toolbox supervisor", %{pid: pid} do
      assert {:undefined, pid, :worker, [Handler]} in DynamicSupervisor.which_children(
               Peasant.Toolbox
             )
    end
  end

  def fake_tool(_context) do
    tool = new_tool() |> FakeTool.new()

    [fake_tool: tool]
  end
end
