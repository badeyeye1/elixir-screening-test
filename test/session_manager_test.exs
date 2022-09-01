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
end
