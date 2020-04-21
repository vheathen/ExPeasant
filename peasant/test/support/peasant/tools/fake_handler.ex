defmodule FakeHandler do
  use GenServer

  import Peasant.Helper

  def register(tool) do
    send(self(), {:register, tool})
    :ok
  end

  def attach(tool_uuid) do
    send(self(), {:attach, tool_uuid})
    :ok
  end

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
