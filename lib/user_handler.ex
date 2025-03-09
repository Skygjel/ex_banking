defmodule UserHandler do
  use GenServer
  def start_link(que_pid) do
    GenServer.start_link(__MODULE__, que_pid)
  end

  def init([que_pid]) do
    {:ok, que_pid}
  end

  def schedule_work(handler_pid, {request, params, from}) do
    GenServer.cast(handler_pid, {request, params, from})
  end

  def handle_cast({request, params, from} , que_pid) do
  case UserQue.schedule_work(que_pid, {request, from, params}) do
    :ok -> :ok
    {:error, :too_many_requests_to_user} -> GenServer.reply(from, {:error, :too_many_requests_to_user})
    {:error, :too_many_requests_to_sender} -> GenServer.reply(from, {:error, :too_many_requests_to_sender})
  end
    {:noreply, que_pid}
  end
end
