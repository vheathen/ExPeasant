defmodule Peasant.EventTest do
  use Peasant.GeneralCase

  defmodule TestEvent1 do
    use Peasant.Event
  end

  @tag :unit
  test "should create struct" do
    assert event = %TestEvent1{}
  end

  defmodule TestEvent2 do
    use Peasant.Event
    event_field(:uuid)
    event_field(:name)
  end

  @tag :unit
  test "should has event_field/1 macro" do
    assert event = %TestEvent2{}
    assert Map.has_key?(event, :uuid)
    assert Map.has_key?(event, :name)
  end

  defmodule TestEvent3 do
    use Peasant.Event

    event_fields([
      :uuid,
      :name
    ])
  end

  @tag :unit
  test "should has event_fields/1 macro" do
    assert event = %TestEvent3{}
    assert Map.has_key?(event, :uuid)
    assert Map.has_key?(event, :name)
  end

  @tag :unit
  test "should have new/1 function" do
    uuid = UUID.uuid4()
    name = Faker.Lorem.word()

    params = [uuid: uuid, name: name]

    assert %TestEvent2{uuid: ^uuid, name: ^name} = TestEvent2.new(params)
    assert %TestEvent3{uuid: ^uuid, name: ^name} = TestEvent3.new(params)
  end
end
