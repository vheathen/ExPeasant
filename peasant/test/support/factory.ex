defmodule Peasant.Factory do
  use ExMachina

  alias Peasant.Tool.Action

  def new_tool_factory do
    %{
      name: Faker.Lorem.word(),
      config: %{},
      placement: Faker.Lorem.sentence(1..4)
    }
  end

  def new_automation_factory do
    %{
      name: Faker.Lorem.word(),
      description: Faker.Lorem.sentence()
    }
  end

  def new_step_factory do
    %{
      description: Faker.Lorem.sentence(),
      type: "action",
      tool_uuid: UUID.uuid4(),
      action: random_action(),
      action_config: %{},
      wait_for_events: false
    }
  end

  def new_step_awaiting_factory do
    %{
      description: Faker.Lorem.sentence(),
      type: "awaiting",
      time_to_wait: Enum.random(10..100),
      wait_for_events: false
    }
  end

  defp random_action do
    [
      Action.TurnOn,
      Action.TurnOff
    ]
    |> Enum.random()
  end
end
