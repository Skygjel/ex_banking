defmodule NaiveBanker do
  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def init(state), do: {:ok, state}

  def handle_call({:create_user, username}, _from, state) do
    case Map.has_key?(state, username) do
      true -> {:reply, {:error, :user_already_exists}, state}
      false -> {:reply, :ok, Map.put(state, username, %{})}
    end
  end

  def handle_call({:deposit, username, amount, currency}, _from, state) do
    {reply, new_state} = deposit(username, amount, currency, state)
    {:reply, reply, new_state}
  end

  def handle_call({:withdraw, username, amount, currency}, _from, state) do
    {reply, new_state} = withdraw(username, amount, currency, state)
    {:reply, reply, new_state}
  end

  def handle_call({:balance, username, currency}, _from, state) do
    case Map.get(state, username) do
      %{} = user ->
        case Map.get(user, currency) do
          nil -> {:reply, {:ok, 0}, state}
          value -> {:reply, {:ok, value}, state}
        end

      nil ->
        {:reply, {:error, :user_does_not_exist}, state}
    end
  end

  def handle_call({:send, from_user, to_user, amount, currency}, _from, state) do
    case withdraw(from_user, amount, currency, state) do
      {{:ok, from_user_balance}, withdrawed_state} ->
        case deposit(to_user, amount, currency, withdrawed_state) do
          {{:ok, to_user_balance}, finished_state} ->
            {:reply, {:ok, from_user_balance, to_user_balance}, finished_state}

          {_error, _state} ->
            {:reply, {:error, :receiver_does_not_exist}, state}
        end

      {{:error, :user_does_not_exist}, _state} ->
        {:reply, {:error, :sender_does_not_exist}, state}

      {error, _state} ->
        {:reply, error, state}
    end
  end

  defp withdraw(username, amount, currency, state) do
    case Map.get(state, username) do
      %{} = user ->
        case Map.get(user, currency) do
          nil ->
            {{:error, :not_enough_money}, state}

          value when value >= amount ->
            new_balance = value - amount
            new_user = Map.put(user, currency, new_balance)
            {{:ok, new_balance}, Map.put(state, username, new_user)}

          _ ->
            {{:error, :not_enough_money}, state}
        end

      nil ->
        {{:error, :user_does_not_exist}, state}
    end
  end

  defp deposit(username, amount, currency, state) do
    case Map.get(state, username) do
      %{} = user ->
        new_balance = user[currency] || 0 + amount
        new_user = Map.put(user, currency, new_balance)
        {{:ok, new_balance}, Map.put(state, username, new_user)}

      nil ->
        {{:error, :user_does_not_exist}, state}
    end
  end
end
