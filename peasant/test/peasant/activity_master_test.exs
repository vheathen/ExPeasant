defmodule Peasant.ActivityMasterTest do
  use Peasant.GeneralCase

  alias Peasant.ActivityMaster, as: Master

  defmodule SimpleGenServer do
    use GenServer
    import Peasant.Helper
    def init(_), do: {:ok, %{}}

    def start_link(%{uuid: uuid} = params),
      do: GenServer.start_link(__MODULE__, params, name: via_tuple(uuid))
  end

  describe "Peasant.ActivityMaster" do
    @describetag :integration

    test "should have been started with the app" do
      assert Process.whereis(Master)
    end

    test " should have add/1 function which is instantiate a given [automation handler] worker process" do
      uuid = UUID.uuid4()

      child_spec = handler_child_spec(SimpleGenServer, %{uuid: uuid})

      assert [] == Registry.lookup(Peasant.Registry, uuid)
      assert {:ok, pid} = Master.add(child_spec)
      assert [{pid, nil}] == Registry.lookup(Peasant.Registry, uuid)
    end
  end
end
