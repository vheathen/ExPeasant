defmodule PeasantWeb.LiveHelpers do
  # General helpers for live views (not-rendering related).
  @moduledoc false

  @doc """
  Computes a route path to the live dashboard.
  """
  def live_peasant_path(socket, action, args \\ [], params \\ []) do
    apply(
      socket.router.__helpers__(),
      :live_peasant_path,
      [socket, action | args] ++ [params]
    )
  end

  @doc """
  Assign default values on the socket.
  """
  def assign_defaults(socket, _params, _session, _refresher? \\ false) do
    Phoenix.LiveView.assign(socket, :menu, %{
      action: socket.assigns.live_action
    })
  end

  # def assign_defaults(socket, params, session, refresher? \\ false) do
  #   param_node = Map.fetch!(params, "node")
  #   found_node = Enum.find([node() | Node.list()], &(Atom.to_string(&1) == param_node))

  #   socket =
  #     Phoenix.LiveView.assign(socket, :menu, %{
  #       refresher?: refresher?,
  #       action: socket.assigns.live_action,
  #       node: found_node || node(),
  #       metrics: session["metrics"],
  #       os_mon: Application.get_application(:os_mon),
  #       request_logger: session["request_logger"]
  #     })

  #   if found_node do
  #     socket
  #   else
  #     Phoenix.LiveView.push_redirect(socket, to: live_dashboard_path(socket, :home, node()))
  #   end
  # end

  def shrink_tool_type(type) when is_atom(type),
    do: type |> Atom.to_string() |> shrink_tool_type()

  def shrink_tool_type("Elixir.Peasant.Tools." <> type), do: type
  def shrink_tool_type(type), do: type
end
