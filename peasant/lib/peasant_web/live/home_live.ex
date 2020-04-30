defmodule PeasantWeb.HomeLive do
  use PeasantWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    socket =
      Phoenix.LiveView.assign(socket, :menu, %{
        action: socket.assigns.live_action
      })

    {:ok, socket}
  end
end
