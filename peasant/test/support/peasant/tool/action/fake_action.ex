defprotocol Peasant.Tool.Action.FakeAction do
  alias Peasant.Tool.Action
  alias Peasant.Tool.Event

  @type t() :: Peasant.Tool.t()
  @type attached_tool :: %{attached: true}

  @spec run(tool :: t(), action_ref :: Action.action_ref()) ::
          {:ok, attached_tool(), [Event.t()]}
          | Action.action_result()
  def run(tool, action_ref)
  def resulting_events(tool)
  def template(tool)
end
