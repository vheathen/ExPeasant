defmodule Peasant.HelperTest do
  use ExUnit.Case

  alias Peasant.Helper

  test "via_tuple/1 should return a correct tuple" do
    uuid = UUID.uuid4()

    assert {:via, Registry, {Peasant.Registry, ^uuid}} = Helper.via_tuple(uuid)
  end

  test "child_spec/2 should return a correct child spec" do
    uuid = UUID.uuid4()
    handler = Peasant.Tool.Handler

    state = %{uuid: uuid, other_params: "SomeValue"}

    assert %{
             id: ^uuid,
             start: {^handler, :start_link, [^state]},
             restart: :transient,
             type: :worker
           } = Helper.handler_child_spec(handler, state)
  end
end
