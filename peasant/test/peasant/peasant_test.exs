defmodule PeasantTest do
  use Peasant.GeneralCase

  @pubsub Peasant.PubSub

  setup do
    topic = "#{Faker.Lorem.word()}:#{Faker.Lorem.word()}"

    message = %{
      event_id: Faker.Lorem.word(),
      tool_uuid: UUID.uuid4()
    }

    Peasant.subscribe(topic)

    [topic: topic, message: message]
  end

  describe "system_state/0" do
    @describetag :integration

    test "should return current system state" do
      assert Peasant.system_state() in [:loading, :ready]
    end
  end

  describe "subscribe/1" do
    @describetag :integration

    test "shoud subscribe current process to given topic messages", %{
      topic: topic,
      message: message
    } do
      Phoenix.PubSub.broadcast(@pubsub, topic, message)

      assert_receive ^message
    end
  end

  describe "broadcast/1" do
    @describetag :integration

    test "shoud broadcast a message to a given topic", %{
      topic: topic,
      message: message
    } do
      Peasant.broadcast(topic, message)

      assert_receive ^message
    end
  end

  describe "build_topic" do
    test "/2 should build a topic in 'left:right' format" do
      assert "left:right" == Peasant.build_topic("left", "right")
    end

    test "/1 should build a topic in 'single' format" do
      assert "single" == Peasant.build_topic("single")
    end
  end
end
