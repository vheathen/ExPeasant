defmodule Peasant.Collection.Keeper do
  @moduledoc false

  @spec child_spec(list()) :: Supervisor.child_spec()
  def child_spec(_ \\ []) do
    cubdb =
      Application.get_env(:peasant, :peasantdb) ||
        raise "no database configuration!"

    %{
      id: __MODULE__,
      start: {
        CubDB,
        :start_link,
        [
          [
            data_dir: cubdb,
            auto_compact: true,
            name: __MODULE__
          ]
        ]
      }
    }
  end

  def db, do: __MODULE__

  def persist(%type{} = record, domain) do
    [pk] = type.__schema__(:primary_key)
    id = Map.get(record, pk)

    now = DateTime.now!("Etc/UTC")

    updated_at = now
    inserted_at = Map.get(record, :inserted_at, now)

    record = %{record | updated_at: updated_at, inserted_at: inserted_at}

    entries = %{
      id => {domain, record},
      {domain, type, id} => true
    }

    CubDB.put_multi(db(), entries)

    record
  end

  def get_by_id(id) do
    case CubDB.get(db(), id) do
      {_domain, record} -> record
      other -> other
    end
  end

  def get_all do
    {:ok, records} = CubDB.select(db())
    records
  end

  def delete(id) do
    db = db()

    case CubDB.get(db, id) do
      {domain, %type{}} -> CubDB.delete_multi(db, [{domain, type, id}, id])
      _ -> :ok
    end
  end
end
