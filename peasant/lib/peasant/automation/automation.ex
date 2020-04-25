defmodule Peasant.Automation do
  @moduledoc """
  Automation domain public API
  """

  alias Peasant.Automation.State

  @opaque t() :: State.t()

  @automation_handler_default Peasant.Automation.Handler

  @spec create(map()) ::
          {:ok, Ecto.UUID}
          | {:error, term()}
  def create(automation_spec) do
    case State.new(automation_spec) do
      {:error, _error} = error ->
        error

      automation ->
        automation_handler().create(automation)
        {:ok, automation.uuid}
    end
  end

  @spec automation_handler :: Peasant.Automation.Handler | atom()
  @doc false
  def automation_handler do
    Application.get_env(:peasant, :automation_handler, @automation_handler_default)
  end
end
