defmodule PanelWeb.PageController do
  use PanelWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
