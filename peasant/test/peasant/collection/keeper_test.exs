defmodule Peasant.Collection.KeeperTest do
  use Peasant.GeneralCase

  alias Peasant.Collection.Keeper

  describe "Keeper" do
    @describetag :unit

    test "db should return a ref to CubDB process" do
      dbdir = Application.get_env(:peasant, :peasantdb)

      assert db = Keeper.db()
      assert CubDB.data_dir(db) == dbdir
    end
  end
end
