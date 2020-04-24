defmodule Peasant.Tool.Event do
  @type t() :: struct()

  defmacro __using__(_) do
    quote do
      alias unquote(__MODULE__)
      alias Peasant.Tool.Action

      defstruct [:action_ref, :tool_uuid, :details]

      # @spec new(tool_uuid :: Ecto.UUID) ::
      #         Event.t()
      # def new(tool_uuid),
      #   do: __new__(tool_uuid: tool_uuid)

      # @spec new(action_ref :: Action.action_ref(), tool_uuid :: Ecto.UUID) ::
      #         Event.t()
      # def new(action_ref, tool_uuid),
      #   do: __new__(action_ref: action_ref, tool_uuid: tool_uuid)

      # @spec new(action_ref :: Action.action_ref(), tool_uuid :: Ecto.UUID, details :: term()) ::
      #         Event.t()
      # def new(action_ref, tool_uuid, event_details),
      #   do: __new__(action_ref: action_ref, tool_uuid: tool_uuid, details: event_details)

      # defoverridable(new: 3, new: 2, new: 1)

      @spec new(params :: map() | keyword()) ::
              Event.t()

      def new(params), do: struct(__MODULE__, params)

      defoverridable(new: 1)
    end
  end
end
