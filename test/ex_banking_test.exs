defmodule ExBankingTest do
  use ExUnit.Case
  doctest ExBanking

  setup do
    start_supervised(NaiveBanker)
    :ok
  end

  test "creates user" do
    assert ExBanking.create_user("testUser1") == :ok
  end

  test "cannot create user if argument isn't string" do
    assert ExBanking.create_user(:thisIsNotUser1) == {:error, :wrong_arguments}
  end

  test "cannot create same user twice" do
    ExBanking.create_user("testUser1") == :ok
    assert ExBanking.create_user("testUser1") == {:error, :user_already_exists}
  end

  test "simple deposit" do
    ExBanking.create_user("testUser2")
    assert ExBanking.deposit("testUser2", 100, "USD") == {:ok, 100}
  end

  test "cannot deposit if user doesn't exist" do
    assert ExBanking.deposit("testUser2", 100, "USD") == {:error, :user_does_not_exist}
  end

  test "cannot deposit if amount is not a number" do
    ExBanking.create_user("testUser2")
    assert ExBanking.deposit("testUser2", "100", "USD") == {:error, :wrong_arguments}
  end

  test "cannot deposit if currency is not a string" do
    ExBanking.create_user("testUser2")
    assert ExBanking.deposit("testUser2", 100, 100) == {:error, :wrong_arguments}
  end

  test "canot deposit if amount is negative" do
    ExBanking.create_user("testUser2")
    assert ExBanking.deposit("testUser5", -100, "USD") == {:error, :wrong_arguments}
  end

  test "simple withdraw" do
    ExBanking.create_user("testUser3")
    ExBanking.deposit("testUser3", 100, "USD") == {:ok, 100}
    assert ExBanking.withdraw("testUser3", 50) == {:ok, 50}
  end

  test "cannot withdraw if user doesn't exist" do
    assert ExBanking.withdraw("testUser3", 50, "USD") == {:error, :user_does_not_exist}
  end

  test "cannot withdraw if amount is not a number" do
    ExBanking.create_user("testUser3")
    ExBanking.deposit("testUser3", 100, "USD") == {:ok, 100}
    assert ExBanking.withdraw("testUser3", "50", "USD") == {:error, :wrong_arguments}
  end

  test "cannot withdraw if currency is not a string" do
    ExBanking.create_user("testUser3")
    ExBanking.deposit("testUser3", 100, "USD") == {:ok, 100}
    assert ExBanking.withdraw("testUser3", 50, 100) == {:error, :wrong_arguments}
  end

  test "cannot withdraw if amount is negative" do
    ExBanking.create_user("testUser3")
    ExBanking.deposit("testUser3", 100, "USD") == {:ok, 100}
    assert ExBanking.withdraw("testUser3", -50, "USD") == {:error, :wrong_arguments}
  end

  test "cannot withdraw if amount is greater than balance" do
    ExBanking.create_user("testUser3")
    ExBanking.deposit("testUser3", 100, "USD") == {:ok, 100}
    ExBanking.deposit("testUser3", 300, "EUR") == {:ok, 300}    # there is no conversion rate implemented in scope
    assert ExBanking.withdraw("testUser3", 150, "USD") == {:error, :not_enough_money}
  end

  test "balance check" do
    ExBanking.create_user("testUser4")
    ExBanking.deposit("testUser4", 100, "USD") == {:ok, 100}
    assert ExBanking.balance("testUser4", "USD") == {:ok, 100}
  end

  test "cannot check balance if user doesn't exist" do
    assert ExBanking.balance("testUser4", "USD") == {:error, :user_does_not_exist}
  end

  test "cannot check balance if currency is not a string" do
    ExBanking.create_user("testUser4")
    ExBanking.deposit("testUser4", 100, "USD") == {:ok, 100}
    assert ExBanking.balance("testUser4", 100, 100) == {:error, :wrong_arguments}
  end

  test "simple send" do
    ExBanking.create_user("testUser5")
    ExBanking.create_user("testUser6")
    ExBanking.deposit("testUser5", 100, "USD") == {:ok, 100}
    assert ExBanking.send("testUser5", "testUser6", 60, "USD") == {:ok, 40, 60}
  end

  test "cannot send if receiver doesn't exist" do
    ExBanking.create_user("testUser5")
    assert ExBanking.send("testUser5", "testUser6", 60, "USD") == {:error, :receiver_does_not_exist}
  end

  test "cannot send if sender dosen't exist" do
    ExBanking.create_user("testUser5")
    assert ExBanking.send("testUser5", "testUser6", 60, "USD") == {:error, :sender_does_not_exist}
  end

  test "cannot send if amount is not a number" do
    ExBanking.create_user("testUser5")
    ExBanking.create_user("testUser6")
    ExBanking.deposit("testUser5", 100, "USD") == {:ok, 100}
    assert ExBanking.send("testUser5", "testUser6", "60", "USD") == {:error, :wrong_arguments}
  end

  test "cannot send if currency is not a string" do
    ExBanking.create_user("testUser5")
    ExBanking.create_user("testUser6")
    ExBanking.deposit("testUser5", 100, "USD") == {:ok, 100}
    assert ExBanking.send("testUser5", "testUser6", 60, 100) == {:error, :wrong_arguments}
  end

  test "cannot send if amount is negative" do
    ExBanking.create_user("testUser5")
    ExBanking.create_user("testUser6")
    ExBanking.deposit("testUser5", 100, "USD") == {:ok, 100}
    assert ExBanking.send("testUser5", "testUser6", -60, "USD") == {:error, :wrong_arguments}
  end

  test "cannot send if amount is greater than balance" do
    ExBanking.create_user("testUser5")
    ExBanking.create_user("testUser6")
    ExBanking.deposit("testUser5", 100, "USD") == {:ok, 100}
    ExBanking.deposit("testUser5", 300, "EUR") == {:ok, 300}    # there is no conversion rate implemented in scope
    assert ExBanking.send("testUser5", "testUser6", 150, "USD") == {:error, :not_enough_money}
  end
end
