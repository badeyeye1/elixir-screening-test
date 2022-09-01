defmodule ElixirInterviewStarter.SessionManagerTest do
  @moduledoc false
  use ExUnit.Case, async: true

  alias ElixirInterviewStarter.CalibrationSession
  alias ElixirInterviewStarter.SessionManager

  test "get_current_state/1 returns `CalibrationSession` given a valid session pid" do
    user_email = "user@mail.com"
    {:ok, session_pid} = SessionManager.start(user_email)

    assert %CalibrationSession{user_email: ^user_email} =
             SessionManager.get_current_state(session_pid)
  end

  describe "precheck1 async message processing" do
    test "updates session state when precheck1 => true message is received" do
      user_email = "user1@mail.com"
      {:ok, session_pid} = SessionManager.start(user_email)
      send(session_pid, %{"precheck1" => true})

      state = SessionManager.get_current_state(session_pid)

      assert state.precheck1 == true
      assert state.status == "PRE_CHECK1_SUCCEDED"
    end

    test "updates session state  to error when precheck1 => false message is received" do
      user_email = "user2@mail.com"
      {:ok, session_pid} = SessionManager.start(user_email)
      send(session_pid, %{"precheck1" => false})

      state = SessionManager.get_current_state(session_pid)

      assert state.precheck1 == false
      assert state.status == "PRE_CHECK1_FAILED"
    end
  end

  describe "precheck2 async message processing" do
    test "updates session state when cartridgeStatus => true message is received" do
      user_email = "jolly@mail.com"
      {:ok, session_pid} = SessionManager.start(user_email)
      send(session_pid, %{"precheck1" => true})
      send(session_pid, %{"cartridgeStatus" => true})

      state = SessionManager.get_current_state(session_pid)

      assert state.cartridge_status == true
    end

    test "updates session state when cartridgeStatus => false message is received" do
      user_email = "jolly1@mail.com"
      {:ok, session_pid} = SessionManager.start(user_email)
      send(session_pid, %{"precheck1" => true})
      send(session_pid, %{"cartridgeStatus" => false})

      state = SessionManager.get_current_state(session_pid)

      assert state.cartridge_status == false
    end

    test "updates session state when submergedInWater => true message is received" do
      user_email = "molly@mail.com"
      {:ok, session_pid} = SessionManager.start(user_email)
      send(session_pid, %{"precheck1" => true})
      send(session_pid, %{"submergedInWater" => true})

      state = SessionManager.get_current_state(session_pid)

      assert state.submerged_in_water == true
    end

    test "updates session state when submergedInWater => false message is received" do
      user_email = "molly1@mail.com"
      {:ok, session_pid} = SessionManager.start(user_email)
      send(session_pid, %{"precheck1" => true})
      send(session_pid, %{"submergedInWater" => false})

      state = SessionManager.get_current_state(session_pid)

      assert state.submerged_in_water == false
    end
  end
end
