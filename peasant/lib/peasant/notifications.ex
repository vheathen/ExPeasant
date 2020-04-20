defmodule Peasant.Notifications do
  @moduledoc false

  alias Phoenix.PubSub

  @pubsub Peasant.PubSub

  def subscribe(topic), do: PubSub.subscribe(@pubsub, topic)

  def broadcast(topic, event), do: PubSub.broadcast(@pubsub, topic, event)
end
