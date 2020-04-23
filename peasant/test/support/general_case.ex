defmodule Peasant.GeneralCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      use ExUnit.Case

      import Peasant.Helper
      import Peasant.Factory
      import Peasant.Fixture

      import Peasant.Tool.TestHelper
    end
  end
end
