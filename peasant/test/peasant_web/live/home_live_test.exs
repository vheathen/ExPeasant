defmodule PeasantWeb.HomeLiveTest do
  use PeasantWeb.ConnCase

  import Phoenix.LiveViewTest

  test "disconnected and connected render", %{conn: conn} do
    {:ok, home_live, disconnected_html} = live(conn, "/")
    assert disconnected_html =~ "Peasant"
    assert render(home_live) =~ "Peasant"
  end
end
