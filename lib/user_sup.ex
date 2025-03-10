defmodule UserSup do
  use Supervisor

  def start_link({username, user_data}) do
    case Supervisor.start_link(__MODULE__, [], strategy: :one_for_all) do
      {:ok, sup} ->
        {:ok, user_worker} = Supervisor.start_child(sup, {UserWorker, user_data})
        {:ok, user_que} = Supervisor.start_child(sup, {UserQue, {username, user_worker}})
        {:ok, user_handler} = Supervisor.start_child(sup, {UserHandler, [user_que]})
        {:ok, user_handler}

      error ->
        error
    end
  end

  def init(_init_arg) do
    Supervisor.init([], strategy: :one_for_all)
  end
end
