defmodule ElixirInterviewStarter.SessionManager do
  @moduledoc """
  A GenServer responsible for managing a device calibration sessions. A new server is created for each device.

  Also processes async messages received from a device and updates the session state accordingly.
  """
  use GenServer
  require Logger

  alias ElixirInterviewStarter.CalibrationSession
  alias ElixirInterviewStarter.DeviceMessages
  alias ElixirInterviewStarter.DeviceRegistry

  # Client API
  @spec start(String.t()) :: {:error, any} | {:ok, pid}
  def start(user_email) do
    name = DeviceRegistry.via_tuple(user_email)
    initial_state = struct(CalibrationSession, user_email: user_email)
    GenServer.start(__MODULE__, initial_state, name: name)
  end

  @spec start_precheck_1(pid) :: CalibrationSession.t()
  def start_precheck_1(session_pid) when is_pid(session_pid) do
    GenServer.call(session_pid, :start_precheck_1, 3000)
  end

  @spec get_session_pid(String.t()) :: {:ok, pid} | {:error, :session_does_not_exist}
  def get_session_pid(user_email) do
    case DeviceRegistry.whereis_name(user_email) do
      :undefined -> {:error, :session_does_not_exist}
      session_pid -> {:ok, session_pid}
    end
  end

  # Callbacks
  @impl GenServer
  def init(initial_state) do
    {:ok, initial_state}
  end

  @impl GenServer
  def handle_call(:start_precheck_1, _from, %CalibrationSession{user_email: user_email} = state) do
    :ok = DeviceMessages.send(user_email, "startPrecheck1")
    new_state = %{state | status: "PRE_CHECK1_STARTED"}
    {:reply, new_state, new_state}
  end

  @impl GenServer
  def handle_info(msg, state) do
    Logger.warn("Received unknown message - #{inspect(msg)}")
    {:noreply, state}
  end
end
