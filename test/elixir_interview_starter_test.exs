defmodule ElixirInterviewStarterTest do
  use ExUnit.Case
  doctest ElixirInterviewStarter
  alias ElixirInterviewStarter.CalibrationSession

  setup do
    %{server_pid: Process.whereis(ElixirInterviewStarter)}
  end

  defp simulate_device_msg(server_pid, payload) do
    send(server_pid, {:device_msg, payload})
  end

  test "it can go through the whole flow happy path" do
  end

  test "start/1 creates a new calibration session and starts precheck 1" do
    user_email = "kelly@mail.com"

    assert {:ok, %CalibrationSession{user_email: ^user_email, status: "PRE_CHECK1_STARTED"}} =
             ElixirInterviewStarter.start(user_email)
  end

  test "start/1 returns an error if the provided user already has an ongoing calibration session" do
    user_email = "nelly@mail.com"
    ElixirInterviewStarter.start(user_email)

    assert {:error, "Calibration already started"} = ElixirInterviewStarter.start(user_email)
  end

  test "start_precheck_2/1 starts precheck 2", %{server_pid: server_pid} do
    user_email = "sally@mail.com"
    ElixirInterviewStarter.start(user_email)
    simulate_device_msg(server_pid, %{"precheck1" => true, "user_email" => user_email})
    :sys.get_state(server_pid)

    assert {:ok,
            %CalibrationSession{
              user_email: ^user_email,
              precheck1: true,
              cartridge_status: nil,
              submerged_in_water: nil,
              status: "PRE_CHECK2_STARTED"
            }} = ElixirInterviewStarter.start_precheck_2(user_email)
  end

  test "start_precheck_2/1 returns an error if the provided user does not have an ongoing calibration session" do
    assert {:error, "No ongoing calibration for user"} =
             ElixirInterviewStarter.start_precheck_2("lolly@mail.com")
  end

  test "start_precheck_2/1 returns an error if the provided user's ongoing calibration session is not done with precheck 1" do
    user_email = "brady@mail.com"
    {:ok, _session_pid} = ElixirInterviewStarter.SessionManager.start(user_email)

    assert {:error, "Not done with precheck 1"} =
             ElixirInterviewStarter.start_precheck_2(user_email)
  end

  test "start_precheck_2/1 returns an error if the provided user's ongoing calibration session is already done with precheck 2",
       %{server_pid: server_pid} do
    user_email = "tracy@mail.com"
    ElixirInterviewStarter.start(user_email)
    simulate_device_msg(server_pid, %{"precheck1" => true, "user_email" => user_email})
    ElixirInterviewStarter.start_precheck_2(user_email)
    simulate_device_msg(server_pid, %{"cartridgeStatus" => true, "user_email" => user_email})
    simulate_device_msg(server_pid, %{"submergedInWater" => true, "user_email" => user_email})
    :sys.get_state(server_pid)

    assert {:error, "Precheck 2 already completed"} =
             ElixirInterviewStarter.start_precheck_2(user_email)
  end

  test "get_current_session/1 returns the provided user's ongoing calibration session" do
    user_email = "jelly@mail.com"
    ElixirInterviewStarter.start(user_email)

    assert {:ok, %CalibrationSession{user_email: ^user_email}} =
             ElixirInterviewStarter.get_current_session(user_email)
  end

  test "get_current_session/1 returns nil if the provided user has no ongoing calibrationo session" do
    assert {:ok, nil} = ElixirInterviewStarter.get_current_session("nosession@mail.com")
  end
end
