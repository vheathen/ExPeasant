defmodule Peasant.Tool.EventTest do
  use Peasant.GeneralCase

  describe "Peasant.Tool.Event" do
    @describetag :unit

    defmodule FakeEvent2 do
      use Peasant.Tool.Event
    end

    test "should allow to 'use' itself and define a new/1 function to create an event struct" do
      ref = UUID.uuid4()
      uuid = UUID.uuid4()
      details = Faker.Lorem.sentences()
      params = [action_ref: ref, tool_uuid: uuid, details: details]

      assert %FakeEvent2{action_ref: ^ref, tool_uuid: ^uuid, details: ^details} =
               FakeEvent2.new(params)

      params = Enum.into(params, %{})

      assert %FakeEvent2{action_ref: ^ref, tool_uuid: ^uuid, details: ^details} =
               FakeEvent2.new(params)

      assert %FakeEvent2{action_ref: ^ref, tool_uuid: ^uuid, details: nil} =
               FakeEvent2.new(action_ref: ref, tool_uuid: uuid)

      assert %FakeEvent2{action_ref: nil, tool_uuid: ^uuid, details: nil} =
               FakeEvent2.new(tool_uuid: uuid)
    end

    defmodule FakeEvent3 do
      use Peasant.Tool.Event

      def new(params), do: struct(__MODULE__, params)
    end

    test "should allow override a new/3 function" do
      ref = UUID.uuid4()
      uuid = UUID.uuid4()
      details = Faker.Lorem.sentences()

      params = [action_ref: ref, tool_uuid: uuid, details: details]

      assert %FakeEvent3{action_ref: ^ref, tool_uuid: ^uuid, details: ^details} =
               FakeEvent3.new(params)
    end
  end
end
