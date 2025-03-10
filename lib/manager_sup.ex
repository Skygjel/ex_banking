defmodule ManagerSup do
  use DynamicSupervisor

  def add_user_sup(username, user_data) do
    DynamicSupervisor.start_child(__MODULE__, {UserSup, {username, user_data}})
  end

  def start_link do
    {:ok, sup} = DynamicSupervisor.start_link(__MODULE__, [], name: __MODULE__)
    DynamicSupervisor.start_child(sup, {ManagerWorkSplitter, %{}})
    {:ok, sup}
  end

  def init(_) do
    DynamicSupervisor.init(strategy: :one_for_one, max_restarts: 5, max_seconds: 5)
  end
end
