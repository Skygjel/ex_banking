defmodule UserQue do
  use GenServer

  def start_link(user_worker) do
    GenServer.start_link(__MODULE__, %{worker_pid: user_worker, que: []})
  end

  def init(state), do: {:ok, state}

  def schedule_work(pid, {request, params, from}) do
    GenServer.call(pid, {request, params, from})
  end

  def task_compleation(pid) do
    GenServer.cast(pid, :task_done)
  end

  # Handling calls from worker handler - if you'd like to add another call, please expand the pattern matching on request tuple
  def handle_call(request_tuple, _from, %{worker_pid: pid, que: que}= state) when length(que) == 0 do
    UserWorker.order_work(pid, request_tuple, self())
    {:reply, :ok, Map.put(state, :que, Enum.concat(que, [request_tuple]))}
  end

  def handle_call(request_tuple, _from,  %{que: que} = state) when length(que) < 10 do
    {:reply, :ok, Map.put(state, :que, Enum.concat(que, [request_tuple]))}
  end

  def handle_call({:send , _, _}, _from, %{que: que} = state) when length(que) > 9 do
    {:reply, {:error, :too_many_requests_to_sender}, state}
  end

  def handle_call(_request_tuple, _from, %{que: que} = state) when length(que) > 9 do
    {:reply, {:error, :too_many_requests_to_user}, state}
  end

  def handle_cast(:task_done, %{worker_pid: pid, que: que} = state) when length(que) > 1 do
    UserWorker.order_work(pid, hd(que), self())
    {:noreply, Map.put(state, :que, tl(que))}
  end

  def handle_cast(:task_done, state) do
    {:noreply, Map.put(state, :que, [])}
  end
end
