defmodule Peasant.DataCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      use Peasant.GeneralCase

      setup do
        on_exit(fn ->
          Peasant.Storage.Observer.clear()
          Application.stop(:peasant)

          case Application.get_env(:peasant, :peasantdb) do
            nil -> :ok
            db -> File.rm_rf(db)
          end

          Application.ensure_all_started(:peasant)
          Peasant.Storage.Observer.clear()
        end)

        :ok
      end
    end
  end
end
