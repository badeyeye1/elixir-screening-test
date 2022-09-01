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
