defmodule StressTest do
  use ExUnit.Case
  doctest ExBanking

  #actuall math doesn't matter for stress tests, we just want to see if the system can handle the load
  setup() do
    ExBanking.create_user("testUser1")
    on_exit(fn -> ExBanking.delete_user("testUser1") end)
end

  test "paralel messaging test" do
    test_pid = self()
    #spawn 100 processes to deposit and 100 to withdraw simultaneously 100 times - we shouldn't get any timeouts and should get at least 1 too_many_requests_to_user error
    for _ <- 1..5000 do
      spawn fn -> ddos_test_helper(&ExBanking.deposit/3, "testUser1", "USD", 20, test_pid) end
      spawn fn -> ddos_test_helper(&ExBanking.withdraw/3, "testUser1", "USD", 2, test_pid) end
    end
    {timeouts, too_many_requests} = compleation_loop(5000)
    assert timeouts == 0
    assert too_many_requests > 0
end

  defp ddos_test_helper(function_to_use, user, currency, amount, process) do
    for _ <- 1..10 do
      case function_to_use.(user, amount, currency) do
        {:error, :timeout} -> send(process, {:error, :timeout})
        {:error, :too_many_requests_to_user} -> send(process, {:error, :too_many_requests_to_user})
        _ -> :ok
      end
    end
    send(process, :done)
  end

  def compleation_loop(expected_compleations), do: compleation_loop(expected_compleations, 0, 0)
  def compleation_loop(0, timeouts, too_many_requests), do: {timeouts, too_many_requests}

  def compleation_loop(expected_compleations, timeouts, too_many_requests) do
    receive do
      {:error, :timeout} -> compleation_loop(expected_compleations, timeouts + 1, too_many_requests)
      {:error, :too_many_requests_to_user} -> compleation_loop(expected_compleations, timeouts, too_many_requests + 1)
      :done -> compleation_loop(expected_compleations - 1, timeouts, too_many_requests)
    end
  end
end
