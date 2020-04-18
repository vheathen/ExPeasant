defmodule Panel.Notifications do
  @moduledoc false

  alias PanelWeb.Endpoint

  @spec notify(
          domain :: String.t() | atom(),
          event :: String.t() | atom(),
          details :: map(),
          system :: Strint.t()
        ) ::
          :ok | {:error, term()}
  def notify(domain, event, details, system \\ "panel")

  def notify(domain, event, details, system) when is_atom(domain) and is_atom(event) do
    notify(Atom.to_string(domain), Atom.to_string(event), details, system)
  end

  def notify(domain, event, details, system) when is_binary(domain) and is_binary(event) do
    Endpoint.broadcast("#{system}:#{domain}", event, details)
  end
end
