defprotocol Peasant.Tool.Action.TurnOff do
  alias Peasant.Tool.Action

  @spec run(tool :: t(), action_ref :: Action.action_ref()) ::
          Action.action_result()
  def run(tool, action_ref)

  def resulting_events(tool)

  def template(tool)
end
