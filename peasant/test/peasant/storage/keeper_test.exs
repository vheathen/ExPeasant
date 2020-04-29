defmodule Peasant.Storage.KeeperTest do
  use Peasant.GeneralCase

  alias Peasant.Storage.Keeper

  describe "Repo" do
    @describetag :unit

    test "db should return a ref to CubDB process" do
      dbdir = Application.get_env(:peasant, :peasantdb)

      assert db = Keeper.db()
      assert is_pid(db)
      assert CubDB.data_dir(db) == dbdir
    end
  end
end
