defmodule Peasant.DataCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      use Peasant.GeneralCase

      setup do
        on_exit(fn ->
          Application.stop(:peasant)

          case Application.get_env(:peasant, :peasantdb) do
            nil -> true
            db -> File.rm(db)
          end

          Application.ensure_all_started(:peasant)
        end)

        :ok
      end
    end
  end
end
