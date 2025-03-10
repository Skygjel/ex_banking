defmodule UserQue do
  use GenServer
  @timeout 5000

  def start_link({username, user_worker}) do
    GenServer.start_link(__MODULE__, %{worker_pid: user_worker, que: [], user: username})
  end

  def init(state), do: {:ok, state}

  def schedule_work(que_pid, {request, params, from}) do
    GenServer.call(que_pid, {request, params, from})
  end

  def task_compleation(que_pid) do
    GenServer.cast(que_pid, :task_done)
  end

  def confirm_death(que_pid) do
    GenServer.call(que_pid, :confirm_death)
  end

  # Handling calls from worker handler - if you'd like to add another call, please expand the pattern matching on request tuple
  def handle_call(request_tuple, _from, %{worker_pid: pid, que: que} = state)
      when length(que) == 0 do
    UserWorker.order_work(pid, request_tuple, self())
    {:reply, :ok, Map.put(state, :que, Enum.concat(que, [request_tuple]))}
  end

  def handle_call(request_tuple, _from, %{que: que} = state) when length(que) < 10 do
    {:reply, :ok, Map.put(state, :que, Enum.concat(que, [request_tuple]))}
  end

  def handle_call({:send, _, _}, _from, %{que: que} = state) when length(que) > 9 do
    {:reply, {:error, :too_many_requests_to_sender}, state}
  end

  def handle_call(_request_tuple, _from, %{que: que} = state) when length(que) > 9 do
    {:reply, {:error, :too_many_requests_to_user}, state}
  end

  def handle_call(:confirm_death, _from, %{que: que} = state) when length(que) > 0 do
    {:reply, :work_resumed, state}
  end

  def handle_call(:confirm_death, _from, %{worker_pid: pid}) do
    {:stop, :normal, :reply, {:ok, UserWorker.return_state_and_stop(pid)}}
  end

  def handle_cast(:task_done, %{worker_pid: pid, que: que} = state) when length(que) > 1 do
    UserWorker.order_work(pid, hd(que), self())
    {:noreply, Map.put(state, :que, tl(que))}
  end

  def handle_cast(:task_done, state) do
    {:noreply, Map.put(state, :que, []), @timeout}
  end

  def handle_info(:timeout, %{user: user} = state) do
    ManagerWorkSplitter.schedule_worker_death(user)
    {:noreply, state}
  end
end
