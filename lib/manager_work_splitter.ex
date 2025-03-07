defmodule ManagerWorkSplitter do
  use GenServer

  def start_link(user_map) do
    GenServer.start_link(__MODULE__, user_map, name: __MODULE__)
  end

  def init(state), do: {:ok, state}

  def handle_call({request, user, params}, from, state) do
    case Map.get(state, user, nil) do
      {pid, _data} ->
        GenServer.cast(pid, {request, params, from})
        {:noreply, state}
      %{} = data ->
        case ManagerSup.add_user_sup(data) do
        {:ok, pid} ->
          GenServer.cast(pid, {request, params, from})
          {:noreply, Map.put(state, user, {pid, data})}
        error ->
          {:reply, error, state}
        end
      nil ->
        case request do
          :send -> {:reply, {:error, :sender_does_not_exist}, state}
          _ -> {:reply, {:error, :user_does_not_exist}, state}
        end
    end
  end

  def handle_call({:create_user, username}, _from, state) do
    case Map.has_key?(state, username) do
      true -> {:reply, {:error, :user_already_exists}, state}
      false -> {:reply, :ok, Map.put(state, username, %{})}
    end
  end

  def handle_call({:delete_user, username}, _from, state) do
    case Map.has_key?(state, username) do
      false -> {:reply, {:error, :user_does_not_exists}, state}
      true -> {:reply, :ok, Map.delete(state, username)}
    end
  end
end
