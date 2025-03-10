defmodule ManagerWorkSplitter do
  use GenServer

  @moduledoc """
  This module is responsible for splitting the work between the user workers.
  It checks if user worker for given user exists, and roues request to it.
  """

  def start_link(user_map) do
    GenServer.start_link(__MODULE__, user_map, name: __MODULE__)
  end

  def init(state), do: {:ok, state}

  def schedule_work({request, user, params}) do
    GenServer.call(__MODULE__, {request, user, params})
  end

  def add_user(username) do
    GenServer.call(__MODULE__, {:create_user, username})
  end

  def delete_user(username) do
    GenServer.call(__MODULE__, {:delete_user, username})
  end

  def schedule_worker_death(username) do
    GenServer.cast(__MODULE__, {:delete_worker, username})
  end

  def handle_call({request, user, params}, from, state) do
    case Map.get(state, user, nil) do
      {pid, _data} ->
        UserHandler.schedule_work(pid, {request, params, from})
        {:noreply, state}

      %{} = data ->
        case ManagerSup.add_user_sup(user, data) do
          {:ok, pid} ->
            UserHandler.schedule_work(pid, {request, params, from})
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

  def handle_cast({:delete_worker, username}, state) do
    {pid, _data} = Map.get(state, username)

    case UserHandler.confirm_death_request(pid) do
      {:ok, new_data} ->
        {:noreply, Map.put(state, username, new_data)}

      :work_resumed ->
        {:noreply, state}
    end
  end
end
