defmodule Peasant.Helper do
  @moduledoc """
  Various support functions
  """

  @spec via_tuple(id :: any) :: {:via, Registry, {PeasantRegistry, any}}
  def via_tuple(id), do: {:via, Registry, {PeasantRegistry, id}}

  @spec handler_child_spec(handler :: atom(), params :: %{required(:uuid) => Ecto.UUID}) ::
          Supervisor.child_spec()
  def handler_child_spec(handler, %{uuid: uuid} = opts),
    do: %{
      id: uuid,
      start: {handler, :start_link, [opts]},
      restart: :transient,
      type: :worker
    }
end
