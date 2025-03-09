defmodule UserWorker do
  use GenServer

  def start_link(data) do
    GenServer.start_link(__MODULE__, data)
  end

  def init({state, sup}), do: {:ok, Map.put(state, :user, sup)}

  def order_work(pid, {request, user, params}, que) do
    GenServer.cast(pid, {{request, user, params}, que})
  end

  def handle_cast({{:deposit, original_caller, [amount, currency]}, que}, state) do
    {reply, new_state} = deposit(amount, currency, state)
    GenServer.reply(original_caller, reply)
    GenServer.cast(que, :task_done)
    {:noreply, new_state}
  end

  def handle_cast({{:withdraw, original_caller, [amount, currency]}, que}, state) do
    {reply, new_state} = withdraw(amount, currency, state)
    GenServer.reply(original_caller, reply)
    GenServer.cast(que, :task_done)
    {:noreply, new_state}
  end

  def handle_cast({{:balance, original_caller, [currency]}, que}, state) do
    GenServer.reply(original_caller, {:ok, Map.get(state, currency, 0)})
    UserQue.task_compleation(que)
    {:noreply, state}
  end

  def handle_cast({{:send, original_caller, [user_to, amount, currency]}, que}, state) do
    {reply, new_state} = withdraw(amount, currency, state)
    case reply do
      {:ok, new_sender_account_value} ->
        case ExBanking.deposit(user_to, amount, currency) do
        {:ok, new_receiver_account_value} ->
          GenServer.reply(original_caller, {:ok, new_sender_account_value, new_receiver_account_value})
        {:error, :user_does_not_exist} ->
          GenServer.reply(original_caller, {:error, :receiver_does_not_exist})
          error -> GenServer.reply(original_caller, error)
      end
      {:error, :not_enough_money} ->
        GenServer.reply(original_caller, {:error, :not_enough_money})
    end
    UserQue.task_compleation(que)
    {:noreply, new_state}
  end

  defp deposit(amount, currency, state) do
    new_value = Map.get(state, currency, 0) + amount
    {{:ok, new_value}, Map.put(state, currency, new_value)}
  end

  defp withdraw(amount, currency, state) do
    case Map.get(state, currency) do
      nil ->
        {{:error, :not_enough_money}, state}

      value when value >= amount ->
        new_balance = value - amount
        {{:ok, new_balance}, Map.put(state, currency, new_balance)}

      _ ->
        {{:error, :not_enough_money}, state}
    end
  end
end
