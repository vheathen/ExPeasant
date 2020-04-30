defmodule Peasant.Automation do
  @moduledoc """
  Automation domain public API
  """

  alias Peasant.Automation.State
  alias Peasant.Automation.State.Step

  @opaque t() :: State.t()

  @automation_handler_default Peasant.Automation.Handler

  @domain "automations"

  @spec domain() :: term()
  def domain, do: @domain

  @spec create(automation_spec :: map()) ::
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

  # @spec delete(automation_uuid :: Ecto.UUID) :: :ok
  # def delete(automation_uuid),
  #   do: automation_handler().delete(automation_uuid)

  @spec rename(automation_uuid :: Ecto.UUID, new_name :: String.t()) ::
          :ok
          | {:error, term()}
  def rename(automation_uuid, new_name),
    do: automation_handler().rename(automation_uuid, new_name)

  @spec activate(automation_uuid :: Ecto.UUID) ::
          :ok
          | {:error, term()}
  def activate(automation_uuid),
    do: automation_handler().activate(automation_uuid)

  @spec deactivate(automation_uuid :: Ecto.UUID) ::
          :ok
          | {:error, term()}
  def deactivate(automation_uuid),
    do: automation_handler().deactivate(automation_uuid)

  @spec add_step_at(
          automation_uuid :: Ecto.UUID,
          step_spec :: map(),
          position :: :first | :last | non_neg_integer()
        ) ::
          {:ok, step_uuid :: Ecto.UUID}
          | {:error, term()}
  def add_step_at(automation_uuid, step_spec, position)
      when position in [:first, :last] or (is_integer(position) and position > 0) do
    case Step.new(step_spec) do
      {:error, _error} = error -> error
      step -> automation_handler().add_step_at(automation_uuid, step, position)
    end
  end

  def add_step_at(_automation_uuid, _step_spec, _position), do: {:error, :incorrect_position}

  @spec delete_step(automation_uuid :: Ecto.UUID, step_uuid :: Ecto.UUID) :: :ok
  def delete_step(automation_uuid, step_uuid),
    do: automation_handler().delete_step(automation_uuid, step_uuid)

  @spec rename_step(automation_uuid :: Ecto.UUID, step_uuid :: Ecto.UUID, new_name :: String.t()) ::
          :ok
          | {:error, term()}
  def rename_step(automation_uuid, step_uuid, new_name),
    do: automation_handler().rename_step(automation_uuid, step_uuid, new_name)

  @spec move_step_to(
          automation_uuid :: Ecto.UUID,
          step_uuid :: Ecto.UUID,
          position :: :first | :last | non_neg_integer()
        ) ::
          :ok
          | {:error, term()}
  def move_step_to(automation_uuid, step_uuid, position)
      when position in [:first, :last] or (is_integer(position) and position > 0) do
    automation_handler().move_step_to(automation_uuid, step_uuid, position)
  end

  def move_step_to(_automation_uuid, _step_uuid, _position), do: {:error, :incorrect_position}

  @spec activate_step(automation_uuid :: Ecto.UUID, step_uuid :: Ecto.UUID) ::
          :ok
          | {:error, term()}
  def activate_step(automation_uuid, step_uuid),
    do: automation_handler().activate_step(automation_uuid, step_uuid)

  @spec deactivate_step(automation_uuid :: Ecto.UUID, step_uuid :: Ecto.UUID) ::
          :ok
          | {:error, term()}
  def deactivate_step(automation_uuid, step_uuid),
    do: automation_handler().deactivate_step(automation_uuid, step_uuid)

  @spec automation_handler :: Peasant.Automation.Handler | atom()
  @doc false
  def automation_handler do
    Application.get_env(:peasant, :automation_handler) || @automation_handler_default
  end
end
