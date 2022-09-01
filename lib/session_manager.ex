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

  @pre_check2_failed "PRE_CHECK2_FAILED"

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

  @spec start_precheck_2(pid) ::
          {:ok, CalibrationSession.t()} | {:error, atom()}
  def(start_precheck_2(session_pid) when is_pid(session_pid)) do
    GenServer.call(session_pid, :start_precheck_2)
  end

  @spec get_session_pid(String.t()) :: {:ok, pid} | {:error, :session_does_not_exist}
  def get_session_pid(user_email) do
    case DeviceRegistry.whereis_name(user_email) do
      :undefined -> {:error, :session_does_not_exist}
      session_pid -> {:ok, session_pid}
    end
  end

  @spec get_current_state(pid) :: CalibrationSession.t()
  def get_current_state(session_pid) do
    GenServer.call(session_pid, :get_current_state)
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

  def handle_call(
        :start_precheck_2,
        _from,
        %CalibrationSession{cartridge_status: true, submerged_in_water: true} = state
      ) do
    {:reply, {:error, :precheck_2_already_completed}, state}
  end

  def handle_call(
        :start_precheck_2,
        _from,
        %CalibrationSession{user_email: user_email, precheck1: true} = state
      ) do
    :ok = DeviceMessages.send(user_email, "startPrecheck2")
    new_state = %{state | status: "PRE_CHECK2_STARTED"}
    {:reply, {:ok, new_state}, new_state}
  end

  def handle_call(:start_precheck_2, _from, state) do
    {:reply, {:error, :pending_precheck_1}, state}
  end

  def handle_call(:get_current_state, _from, state) do
    {:reply, state, state}
  end

  @impl GenServer
  def handle_info(%{"precheck1" => true}, state) do
    {:noreply, %{state | precheck1: true, status: "PRE_CHECK1_SUCCEDED"}}
  end

  def handle_info(%{"precheck1" => _val}, state) do
    {:noreply, %{state | precheck1: false, status: "PRE_CHECK1_FAILED"}}
  end

  def handle_info(%{"cartridgeStatus" => true}, state) do
    {:noreply, %{state | cartridge_status: true}}
  end

  def handle_info(%{"cartridgeStatus" => _}, state) do
    {:noreply, %{state | cartridge_status: false, status: @pre_check2_failed}}
  end

  def handle_info(%{"submergedInWater" => true}, state) do
    new_state = %{state | submerged_in_water: true, status: "PRE_CHECK2_SUCCEEDED"}
    {:noreply, new_state}
  end

  def handle_info(%{"submergedInWater" => _}, state) do
    {:noreply, %{state | submerged_in_water: false, status: @pre_check2_failed}}
  end

  def handle_info(msg, state) do
    Logger.warn("Received unknown message - #{inspect(msg)}")
    {:noreply, state}
  end
end
