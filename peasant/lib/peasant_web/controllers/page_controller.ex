defmodule PeasantWeb.PageController do
  use PeasantWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
