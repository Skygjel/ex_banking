defmodule ExBankingTest do
  use ExUnit.Case
  doctest ExBanking

  setup do
    ExBanking.create_user("testUser")
    on_exit(fn -> ExBanking.delete_user("testUser") end)
  end

  test "creates user" do
    assert ExBanking.create_user("testUser1") == :ok
  end

  test "cannot create user if argument isn't string" do
    assert ExBanking.create_user(:thisIsNotUser1) == {:error, :wrong_arguments}
  end

  test "cannot create same user twice" do
    assert ExBanking.create_user("testUser") == {:error, :user_already_exists}
  end

  test "simple deposit" do
    ExBanking.create_user("testUser")
    assert ExBanking.deposit("testUser", 100, "USD") == {:ok, 100}
  end

  test "cannot deposit if user doesn't exist" do
    assert ExBanking.deposit("NOTtestUser", 100, "USD") == {:error, :user_does_not_exist}
  end

  test "cannot deposit if amount is not a number" do
    assert ExBanking.deposit("testUser", "100", "USD") == {:error, :wrong_arguments}
  end

  test "cannot deposit if currency is not a string" do
    assert ExBanking.deposit("testUser", 100, 100) == {:error, :wrong_arguments}
  end

  test "canot deposit if amount is negative" do
    assert ExBanking.deposit("testUser", -100, "USD") == {:error, :wrong_arguments}
  end

  test "simple withdraw" do
    ExBanking.deposit("testUser", 100, "USD")
    assert ExBanking.withdraw("testUser", 50, "USD") == {:ok, 50}
  end

  test "cannot withdraw if user doesn't exist" do
    assert ExBanking.withdraw("NOTtestUser", 50, "USD") == {:error, :user_does_not_exist}
  end

  test "cannot withdraw if amount is not a number" do
    ExBanking.deposit("testUser", 100, "USD")
    assert ExBanking.withdraw("testUser", "50", "USD") == {:error, :wrong_arguments}
  end

  test "cannot withdraw if currency is not a string" do
    ExBanking.deposit("testUser", 100, "USD")
    assert ExBanking.withdraw("testUser", 50, 100) == {:error, :wrong_arguments}
  end

  test "cannot withdraw if amount is negative" do
    ExBanking.deposit("testUser", 100, "USD")
    assert ExBanking.withdraw("testUser", -50, "USD") == {:error, :wrong_arguments}
  end

  test "cannot withdraw if amount is greater than balance" do
    ExBanking.deposit("testUser", 100, "USD")
    # there is no conversion rate implemented in scope
    ExBanking.deposit("testUser", 300, "EUR")
    assert ExBanking.withdraw("testUser", 150, "USD") == {:error, :not_enough_money}
  end

  test "balance check" do
    ExBanking.deposit("testUser", 100, "USD")
    assert ExBanking.balance("testUser", "USD") == {:ok, 100}
  end

  test "cannot check balance if user doesn't exist" do
    assert ExBanking.balance("NOTtestUser", "USD") == {:error, :user_does_not_exist}
  end

  test "cannot check balance if currency is not a string" do
    ExBanking.deposit("testUser", 100, "USD")
    assert ExBanking.balance("testUser", 100) == {:error, :wrong_arguments}
  end

  test "simple send" do
    ExBanking.create_user("testUserReceiver")
    ExBanking.deposit("testUser", 100, "USD")
    assert ExBanking.send("testUser", "testUserReceiver", 60, "USD") == {:ok, 40, 60}
  end

  test "cannot send if receiver doesn't exist" do
    ExBanking.deposit("testUser", 100, "USD")
    assert ExBanking.send("testUser", "NOTtestUser", 60, "USD") ==
             {:error, :receiver_does_not_exist}
  end

  test "cannot send if sender dosen't exist" do
    assert ExBanking.send("NOTtestUser", "testUser", 60, "USD") == {:error, :sender_does_not_exist}
  end

  test "cannot send if amount is not a number" do
    ExBanking.create_user("testUserReceiver")
    ExBanking.deposit("testUser", 100, "USD")
    assert ExBanking.send("testUser", "testUserReceiver", "60", "USD") == {:error, :wrong_arguments}
  end

  test "cannot send if currency is not a string" do
    ExBanking.create_user("testUserReceiver")
    ExBanking.deposit("testUser", 100, "USD")
    assert ExBanking.send("testUser", "testUserReceiver", 60, 100) == {:error, :wrong_arguments}
  end

  test "cannot send if amount is negative" do
    ExBanking.create_user("testUserReceiver")
    ExBanking.deposit("testUser", 100, "USD")
    assert ExBanking.send("testUser", "testUserReceiver", -60, "USD") == {:error, :wrong_arguments}
  end

  test "cannot send if amount is greater than balance" do
    ExBanking.create_user("testUserReceiver")
    ExBanking.deposit("testUser", 100, "USD")
    # there is no conversion rate implemented in scope
    ExBanking.deposit("testUser", 300, "EUR")
    assert ExBanking.send("testUser", "testUserReceiver", 150, "USD") == {:error, :not_enough_money}
  end
end
