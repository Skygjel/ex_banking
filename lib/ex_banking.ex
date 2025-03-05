defmodule ExBanking do
  @moduledoc """
  Documentation for `ExBanking`.
  """

  @doc """

  """
  def start_link() do
    spawn(NaiveBanker, :start_link, [])
  end

  def stop() do
    GenServer.stop(NaiveBanker)
  end

  @spec create_user(user :: String.t()) :: :ok | {:error, :wrong_arguments | :user_already_exists}
  def create_user(user_name) when is_binary(user_name) do
    GenServer.call(NaiveBanker, {:create_user, user_name})
  end

  def create_user(_), do: {:error, :wrong_arguments}

  @spec deposit(user :: String.t(), amount :: number, currency :: String.t()) ::
          {:ok, number} | {:error, :wrong_arguments | :user_does_not_exist}
  def deposit(user_name, amount, currency)
      when is_binary(user_name) and is_number(amount) and amount > 0 and is_binary(currency) do
    GenServer.call(NaiveBanker, {:deposit, user_name, amount, currency})
  end

  def deposit(_, _, _), do: {:error, :wrong_arguments}

  @spec withdraw(user :: String.t(), amount :: number, currency :: String.t()) ::
          {:ok, number} | {:error, :wrong_arguments | :user_does_not_exist}
  def withdraw(user_name, amount, currency)
      when is_binary(user_name) and is_number(amount) and amount > 0 and is_binary(currency) do
    GenServer.call(NaiveBanker, {:withdraw, user_name, amount, currency})
  end

  def withdraw(_, _, _), do: {:error, :wrong_arguments}

  @spec balance(user :: String.t(), currency :: String.t()) ::
          {:ok, number} | {:error, :user_does_not_exist}
  def balance(user_name, currency) when is_binary(user_name) and is_binary(currency) do
    GenServer.call(NaiveBanker, {:balance, user_name, currency})
  end

  def balance(_, _), do: {:error, :wrong_arguments}

  @spec send(
          from_user :: String.t(),
          to_user :: String.t(),
          amount :: number,
          currency :: String.t()
        ) ::
          {:ok, number} | {:error, :wrong_arguments | :user_does_not_exist}
  def send(from_user, to_user, amount, currency)
      when is_binary(from_user) and is_binary(to_user) and is_number(amount) and amount > 0 and
             is_binary(currency) do
    GenServer.call(NaiveBanker, {:send, from_user, to_user, amount, currency})
  end

  def send(_, _, _, _), do: {:error, :wrong_arguments}
end
