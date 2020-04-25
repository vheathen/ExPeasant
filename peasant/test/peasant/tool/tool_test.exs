defmodule Peasant.ToolTest do
  use Peasant.GeneralCase

  alias Peasant.Tool

  alias Peasant.Tools.FakeTool

  setup_all do
    tool_handler = Application.get_env(:peasant, :tool_handler)
    Application.put_env(:peasant, :tool_handler, Tool.FakeHandler)

    on_exit(fn ->
      Application.put_env(:peasant, :tool_handler, tool_handler)
    end)
  end

  setup do
    tool_spec = new_tool()

    assert %FakeTool{} = tool = FakeTool.new(tool_spec)

    [tool_spec: tool_spec, tool: tool]
  end

  describe "Tool module" do
    @describetag :unit

    test "should intoduce State struct and functions", do: :ok
  end

  describe "Tool module events" do
    @describetag :unit

    # test "should introduce __Tool__.Registered event struct", %{tool: tool} do
    #   assert Code.ensure_compiled(FakeTool.Registered)
    #   assert %FakeTool.Registered{tool: ^tool} = FakeTool.Registered.new(%{tool: tool})
    # end

    # test "should introduce __Tool__.Attached event struct", %{tool: tool} do
    #   assert Code.ensure_compiled(FakeTool.Attached)
    #   assert %FakeTool.Attached{tool: ^tool} = FakeTool.Attached.new(%{tool: tool})
    # end

    # test "should introduce __Tool__.AttachmentFailed event struct", %{tool: tool} do
    #   assert Code.ensure_compiled(FakeTool.AttachmentFailed)

    #   reason = Faker.Lorem.word()

    #   assert %FakeTool.AttachmentFailed{tool_uuid: tool.uuid, reason: reason} ==
    #            FakeTool.AttachmentFailed.new(%{tool_uuid: tool.uuid, reason: reason})

    #   assert %FakeTool.AttachmentFailed{tool_uuid: tool.uuid, reason: reason} ==
    #            FakeTool.AttachmentFailed.new(tool_uuid: tool.uuid, reason: reason)
    # end
  end

  describe "Registration and register/1" do
    @describetag :unit

    test "should return {:ok, uuid} in case of correct tool specs", %{tool_spec: tool_spec} do
      assert {:ok, uuid} = Tool.register(FakeTool, tool_spec)
      assert is_binary(uuid)
      assert {:ok, _} = UUID.info(uuid)

      assert_receive {:register, %FakeTool{uuid: ^uuid}}
    end

    test "should return {:error, error} in case of incorrect tool specs" do
      tool = new_tool() |> Map.delete(:name)
      assert {:error, _} = Tool.register(FakeTool, tool)

      refute_receive {:register, %FakeTool{}}
    end
  end

  describe "commit(tool_uuid, action, action_config \\ %{})" do
    @describetag :unit

    test "should run Handler.commit(tool_uuid, action)", %{tool: %{uuid: uuid}} do
      assert {:ok, _ref} = Peasant.Tool.commit(uuid, Peasant.Tool.Action.Attach)
      assert_receive {:commit, ^uuid, Peasant.Tool.Action.Attach, %{}}
    end

    test "should run Handler.commit(tool_uuid, action, config)", %{tool: %{uuid: uuid}} do
      config = %{key: "value"}

      assert {:ok, _ref} =
               Peasant.Tool.commit(
                 uuid,
                 Peasant.Tool.Action.Attach,
                 config
               )

      assert_receive {:commit, ^uuid, Peasant.Tool.Action.Attach, ^config}
    end
  end
end
