defmodule Peasant.Tool.Action do
  @moduledoc """
  Doesn't work as of yet

  Should give an opportunity to describe two type of actions - with config and without config -
  as a protocol via `use/2` macro.

  But in overal each action should have:
  """

  @type t :: struct()

  @type action_ref :: Ecto.UUID
  @type action_config :: term()
  @type action_config_template :: t()

  @type action_result :: {:ok, Peasant.Tool.t(), [Peasant.Tool.Event.t()]}
  @type action_config_error :: {:error, :config_error, errors :: term(), Peasant.Tool.t()}

  ##
  #
  # Callbacks
  #

  @callback run(tool :: Peasant.Tool.t(), action_ref :: Ecto.UUID) ::
              action_result()

  #
  # or
  #

  @callback run(
              tool :: Peasant.Tool.t(),
              action_ref :: Ecto.UUID,
              config :: Peasant.Tool.Action.action_config()
            ) ::
              action_result()
              | action_config_error()

  @callback resulting_events(tool :: Peasant.Tool.t()) :: [Peasant.Tool.Event.t()]

  @callback template(tool :: Peasant.Tool.t()) :: action_config_template()

  @callback persist_after?(tool :: Peasant.Tool.t()) :: boolean()

  ### To insert into defprotocol:
  ##
  # defprotocol Peasant.Tool.Action._ACTION_NAME_ do
  #   def run(tool, action_ref, config)
  #   def resulting_events(tool)
  #   def template(tool)
  # end

  # @callback run(tool :: Peasant.Tool.t(), action_ref :: Ecto.UUID, config :: action_config()) ::
  #             {:ok, [Peasant.Tool.Event.t()]}

  # defmacro __using__([:protocol | opts]) do
  #   has_config? = :has_config in opts

  #   quote do
  #   end
  # end

  # defmacro __using__(_) do
  #   quote do
  #     import unquote(__MODULE__)

  #     # def new(params), do: struct(__MODULE__, params)

  #     def label, do: ""

  #     defoverridable(label: 0)
  #   end
  # end

  # defmacro label(label) do
  #   quote do
  #     def label(), do: unquote(label)
  #   end
  # end

  # def protocol(opts) do
  #   case Keyword.get(opts, :no_config) do
  #     true ->
  #       quote do
  #         use Peasant.Tool.Action.ProtocolWithoutConfig
  #       end

  #     _ ->
  #       quote do
  #         use Peasant.Tool.Action.ProtocolWithConfig
  #       end
  #   end
  # end

  # def callback_run_with_config do
  #   quote do
  #     @callback run(
  #                 tool :: Peasant.Tool.t(),
  #                 action_ref :: Ecto.UUID,
  #                 config :: Peasant.Tool.Action.action_config()
  #               ) ::
  #                 {:ok, [Peasant.Tool.Event.t()]}
  #   end
  # end

  # def run_with_config do
  #   quote do
  #     @spec run(
  #             tool :: Peasant.Tool.t(),
  #             action_ref :: Ecto.UUID,
  #             config :: Peasant.Tool.Action.action_config()
  #           ) ::
  #             {:ok, [Peasant.Tool.Event.t()]}
  #     def run(tool, action_ref, action_config)
  #   end
  # end

  # def callback_run_no_config do
  #   quote do
  #     @callback run(tool :: Peasant.Tool.t(), action_ref :: Ecto.UUID) ::
  #                 {:ok, [Peasant.Tool.Event.t()]}
  #   end
  # end

  # defmacro run_no_config do
  #   quote do
  #     @spec run(tool :: Peasant.Tool.t(), action_ref :: Ecto.UUID) ::
  #             {:ok, [Peasant.Tool.Event.t()]}
  #     def run(tool, action_ref)
  #   end
  # end

  # defmacro __using__(opts) do
  #   case Keyword.get(opts, :type) do
  #     :protocol -> apply(__MODULE__, :protocol, [opts])
  #     :impl -> nil
  #     _ -> raise "Action: type is not set!"
  #   end
  # end
end

# defmodule Peasant.Tool.Action.ProtocolWithoutConfig do
#   defmacro __using__(_) do
#     quote do
#       def run(tool, ref)
#     end
#   end
# end

# defmodule Peasant.Tool.Action.ProtocolWithConfig do
#   import Peasant.Tool.Action

#   callback_run_with_config()
# end
