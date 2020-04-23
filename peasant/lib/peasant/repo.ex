defmodule Peasant.Repo do
  use GenServer

  def db, do: GenServer.call(__MODULE__, :db)

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

  def delete(id) do
    db = db()

    case CubDB.get(db, id) do
      {domain, %type{}} -> CubDB.delete_multi(db, [{domain, type, id}, id])
      _ -> :ok
    end
  end

  #### Internals

  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    cubdb = Application.get_env(:peasant, :peasantdb) || raise "no database configuration!"
    {:ok, db} = CubDB.start_link(data_dir: cubdb, auto_compact: true)

    {:ok, db}
  end

  def handle_call(:db, _from, db) do
    {:reply, db, db}
  end
end
