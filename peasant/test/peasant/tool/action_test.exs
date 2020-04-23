# defmodule Peasant.Tool.ActionTest do
#   use Peasant.GeneralCase

#   # defmodule Action do
#   #   use Peasant.Tool.Action

#   #   label(Faker.Lorem.sentence(2..4))
#   # end

#   # defmodule ActionNoLabel do
#   #   use Peasant.Tool.Action
#   # end

#   alias Peasant.Tools.FakeTool

#   alias Peasant.Tool.Action.{
#     FakeActionNoConfig,
#     FakeActionWithConfig
#   }

#   describe "use Action, :protocol, :no_config should describe a protocol" do
#     # test "which has run(tool, action_ref) definition" do
#     #   tool = new_tool() |> FakeTool.new()
#     #   action_ref = UUID.uuid4()

#     #   assert {:ok, _} = FakeActionNoConfig.run(tool, action_ref)
#     # end

#     # test "namespace should have Action.WithConfig and Action.WithoutConfig behaviour modules" do
#     #   assert {:module, Action.WithConfig} == Code.ensure_compiled(Action.WithConfig)
#     #   assert {:module, Action.WithoutConfig} == Code.ensure_compiled(Action.WithoutConfig)
#     # end

#     # test "+ WithConfig and WithoutConfig should describe behaviour" do
#     #   assert is_list(Action.WithConfig.behaviour_info(:callbacks))
#     #   assert is_list(Action.WithoutConfig.behaviour_info(:callbacks))
#     # end
#   end

#   describe "using Action with :protocol option" do
#     @describetag :unit

#     # test "should "
#   end

#   # test "shoud have a new method and required fields" do
#   #   uuid = UUID.uuid4()
#   #   config = %{time: 123}

#   #   assert %Action{tool_uuid: ^uuid, config: ^config} =
#   #            Action.new(uuid, config)
#   # end

#   # test "shouldn't have :config key if :no_config given" do
#   #   uuid = UUID.uuid4()
#   #   config = %{time: 123}

#   #   assert action = ActionNoLabel.new(tool_uuid: uuid, config: config)

#   #   assert %ActionNoLabel{tool_uuid: ^uuid} == action

#   #   refute Map.has_key?(action, :config)
#   # end

#   # test "should have label/1 macro which gives label/0 func returning label/1 macro option" do
#   #   assert is_binary(Action.label())
#   #   assert byte_size(Action.label()) > 0

#   #   assert is_binary(ActionNoLabel.label())
#   #   assert byte_size(ActionNoLabel.label()) == 0
#   # end
# end
