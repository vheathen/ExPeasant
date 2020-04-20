defmodule Peasant do
  @moduledoc """
  Peasant keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """

  alias Phoenix.PubSub

  @pubsub Peasant.PubSub

  def subscribe(topic), do: PubSub.subscribe(@pubsub, topic)

  def broadcast(topic, event), do: PubSub.broadcast(@pubsub, topic, event)

  @spec build_topic(String.t()) :: String.t()
  def build_topic(single) when is_binary(single), do: single

  @spec build_topic(String.t(), String.t()) :: <<_::8, _::_*8>>
  def build_topic(left, right) when is_binary(left) and is_binary(right), do: "#{left}:#{right}"
end
