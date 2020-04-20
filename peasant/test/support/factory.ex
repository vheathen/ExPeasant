defmodule Peasant.Factory do
  use ExMachina

  def new_fake_tool_factory do
    %{
      name: Faker.Lorem.word(),
      config: %{},
      placement: Faker.Lorem.sentence(1..4)
    }
  end
end
