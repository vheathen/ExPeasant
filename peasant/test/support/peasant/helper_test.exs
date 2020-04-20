defmodule Peasant.HelperTest do
  use ExUnit.Case

  alias Peasant.Helper

  test "via_tuple/1 should return a correct tuple" do
    uuid = UUID.uuid4()

    assert {:via, Registry, {PeasantRegistry, ^uuid}} = Helper.via_tuple(uuid)
  end
end
