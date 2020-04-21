defmodule Peasant.Tools.FakeTool do
  use Peasant.Tool

  @impl Peasant.Tool
  def do_attach(tool) do
    send(tool.config.pid, {:do_attach, tool})

    case tool do
      %{config: %{error: error}} ->
        {:error, error}

      _ ->
        {:ok, tool}
    end
  end
end
