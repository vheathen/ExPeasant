defprotocol Peasant.Tool.Action.Attach do
  @fallback_to_any true

  alias Peasant.Tool.Action
  alias Peasant.Tool.Event

  @type t() :: Peasant.Tool.t()
  @type attached_tool :: %{:attached => true, optional(atom()) => term()}
  @type not_attached_tool :: %{attached: false}

  @type attached_result :: {:ok, attached_tool(), [Event.Attached.t()]}
  @type not_attached_result :: {:ok, attached_tool(), [Event.NotAttached.t()]}

  @spec run(tool :: t(), action_ref :: Action.action_ref()) ::
          attached_result()
          | not_attached_result()
  def run(tool, action_ref)
  def resulting_events(tool)
  def template(tool)
  def persist_after?(tool)
end

defimpl Peasant.Tool.Action.Attach, for: Any do
  alias Peasant.Tool.Event

  def run(%_{uuid: uuid, attached: _} = tool, action_ref) do
    event = Event.Attached.new(tool_uuid: uuid, action_ref: action_ref)
    {:ok, %{tool | attached: true}, [event]}
  end

  def resulting_events(_tool), do: [Attached]
  def template(_tool), do: %{}

  def persist_after?(_tool), do: true
end

# defmodule Peasant.Tool.Action.Attach.Meta do
#   def label, do: "Some label"
# end
