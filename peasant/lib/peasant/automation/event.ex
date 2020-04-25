defmodule Peasant.Automation.Event do
  @type t() :: struct()

  defmacro __using__(_) do
    quote do
      alias unquote(__MODULE__)
      alias Peasant.Automation.Action

      defstruct [:action_ref, :automation_uuid, :details]

      @spec new(params :: map() | keyword()) ::
              Event.t()

      def new(params), do: struct(__MODULE__, params)

      defoverridable(new: 1)
    end
  end
end
