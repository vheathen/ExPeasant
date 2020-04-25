defmodule Peasant.Automation.EventTest do
  use Peasant.GeneralCase

  describe "Peasant.Automation.Event" do
    @describetag :unit

    defmodule FakeEvent2 do
      use Peasant.Automation.Event
    end

    test "should allow to 'use' itself and define [:automation_uuid, :action_ref] struct" do
      ref = UUID.uuid4()
      uuid = UUID.uuid4()
      params = [action_ref: ref, automation_uuid: uuid]

      assert %FakeEvent2{action_ref: ref, automation_uuid: uuid} == FakeEvent2.new(params)
    end
  end
end
