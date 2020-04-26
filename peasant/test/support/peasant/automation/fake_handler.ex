defmodule Peasant.Automation.FakeHandler do
  use GenServer

  import Peasant.Helper

  def create(automation) do
    send(self(), {:create, automation})
    :ok
  end

  def delete(automation_uuid) do
    send(self(), {:delete, automation_uuid})
    :ok
  end

  def rename(automation_uuid, new_name) do
    send(self(), {:rename, automation_uuid, new_name})
    :ok
  end

  def add_step_at(automation_uuid, step, position) do
    send(self(), {:add_step_at, automation_uuid, step, position})
    :ok
  end

  def delete_step(automation_uuid, step_uuid) do
    send(self(), {:delete_step, automation_uuid, step_uuid})
    :ok
  end

  def rename_step(automation_uuid, step_uuid, new_name) do
    send(self(), {:rename_step, automation_uuid, step_uuid, new_name})
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
