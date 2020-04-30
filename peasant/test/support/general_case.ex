defmodule Peasant.GeneralCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      use ExUnit.Case, async: false

      import Peasant.Helper
      import Peasant.Factory
      import Peasant.Fixture

      import Peasant.TestHelper

      @tools Peasant.Tool.domain()
      @automations Peasant.Automation.domain()

      setup do
        {:ok, _} = Application.ensure_all_started(:peasant, :transient)

        config = Application.get_all_env(:peasant)

        on_exit(fn ->
          Application.put_all_env([{:peasant, config}])

          db = Application.get_env(:peasant, :peasantdb)
          Application.stop(:peasant)

          case db do
            nil -> :ok
            db -> File.rm_rf(db)
          end

          {:ok, _} = Application.ensure_all_started(:peasant, :transient)
        end)
      end
    end
  end
end
