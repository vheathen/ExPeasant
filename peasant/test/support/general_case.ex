defmodule Peasant.GeneralCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      use ExUnit.Case

      import Peasant.Helper
      import Peasant.Factory
      import Peasant.Fixture

      import Peasant.TestHelper

      setup do
        config = Application.get_all_env(:peasant)

        on_exit(fn ->
          Application.put_all_env([{:peasant, config}])
        end)
      end
    end
  end
end
