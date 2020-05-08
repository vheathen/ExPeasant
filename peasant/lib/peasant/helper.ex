defmodule Peasant.Helper do
  @moduledoc """
  Various support functions
  """

  @spec via_tuple(id :: any) :: {:via, Registry, {Peasant.Registry, any}}
  def via_tuple(id), do: {:via, Registry, {Peasant.Registry, id}}

  @spec handler_child_spec(handler :: atom(), params :: %{required(:uuid) => Ecto.UUID}) ::
          Supervisor.child_spec()
  def handler_child_spec(handler, %{uuid: uuid} = opts),
    do: %{
      id: uuid,
      start: {handler, :start_link, [opts]},
      restart: :transient,
      type: :worker
    }

  @spec now :: non_neg_integer()
  def now,
    do: DateTime.utc_now() |> DateTime.to_unix(:millisecond)
end
