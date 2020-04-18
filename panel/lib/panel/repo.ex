defmodule Panel.Repo do
  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def get_db(), do: GenServer.call(__MODULE__, :get_db)

  def persist(%Ecto.Changeset{valid?: false, errors: errors}, _domain),
    do: {:error, :expected_valid_changeset, errors}

  def persist(%Ecto.Changeset{valid?: true, data: %type{}} = changeset, domain) do
    [pk] = type.__schema__(:primary_key)

    record = Ecto.Changeset.apply_changes(changeset)
    id = Map.get(record, pk)

    now = DateTime.now!("Etc/UTC")

    updated_at = Map.get(record, :updated_at, now)
    inserted_at = Map.get(record, :inserted_at, now)

    record = %{record | updated_at: updated_at, inserted_at: inserted_at}

    db = get_db()

    entries = %{
      id => {domain, record},
      {domain, type, id} => true
    }

    CubDB.put_multi(db, entries)

    record
  end

  def get_by_id(id) do
    case CubDB.get(get_db(), id) do
      {_domain, record} -> record
      other -> other
    end
  end

  def delete(id) do
    db = get_db()

    case CubDB.get(db, id) do
      {domain, %type{}} -> CubDB.delete_multi(db, [{domain, type, id}, id])
      _ -> :ok
    end
  end

  #### Internals

  def init(_) do
    cubdb = Application.get_env(:panel, :paneldb, "data/paneldb")
    {:ok, db} = CubDB.start_link(data_dir: cubdb, auto_compact: true)

    {:ok, db}
  end

  def handle_call(:get_db, _from, db) do
    {:reply, db, db}
  end
end
