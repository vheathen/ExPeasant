defmodule Peasant.Automation.EventTest do
  use Peasant.GeneralCase

  describe "Peasant.Automation.Event" do
    @describetag :unit

    defmodule FakeEvent2 do
      use Peasant.Automation.Event
    end

    test "should allow to 'use' itself and define a new/1 function to create an event struct" do
      ref = UUID.uuid4()
      uuid = UUID.uuid4()
      details = Faker.Lorem.sentences()
      params = [action_ref: ref, automation_uuid: uuid, details: details]

      assert %FakeEvent2{action_ref: ref, automation_uuid: uuid, details: details} =
               FakeEvent2.new(params)

      params = Enum.into(params, %{})

      assert %FakeEvent2{action_ref: ref, automation_uuid: uuid, details: details} =
               FakeEvent2.new(params)

      assert %FakeEvent2{action_ref: ref, automation_uuid: uuid, details: nil} =
               FakeEvent2.new(action_ref: ref, automation_uuid: uuid)

      assert %FakeEvent2{action_ref: nil, automation_uuid: uuid, details: nil} =
               FakeEvent2.new(automation_uuid: uuid)
    end

    defmodule FakeEvent3 do
      use Peasant.Automation.Event

      def new(params), do: struct(__MODULE__, params)
    end

    test "should allow override a new/1 function" do
      ref = UUID.uuid4()
      uuid = UUID.uuid4()
      details = Faker.Lorem.sentences()

      params = [action_ref: ref, automation_uuid: uuid, details: details]

      assert %FakeEvent3{action_ref: ref, automation_uuid: uuid, details: details} =
               FakeEvent3.new(params)
    end
  end
end
