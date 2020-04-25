defmodule Peasant.Automation.Handler do
  use GenServer

  @domain "automations"

  alias Peasant.Automation.State

  import Peasant.Helper

  ###
  # Internal Public API
  #

  def start_link(%{uuid: uuid} = automation),
    do: GenServer.start_link(__MODULE__, automation, name: via_tuple(uuid))

  def create(automation),
    do: __MODULE__ |> handler_child_spec(automation) |> Peasant.ActivityMaster.add()

  ####
  # Implementation
  #

  def init(%State{new: true} = automation) do
    {:ok, %{automation | new: false}, {:continue, :created}}
  end

  def handle_continue(:created, automation) do
    event =
      Peasant.Automation.Event.Created.new(
        automation_uuid: automation.uuid,
        details: %{automation: automation}
      )

    notify(event)

    {:noreply, automation}
  end

  defp notify(events) when is_list(events), do: Enum.each(events, &notify/1)
  defp notify(event), do: Peasant.broadcast(@domain, event)
end
