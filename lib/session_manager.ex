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
  @pre_check2_started "PRE_CHECK2_STARTED"
  @calibration_failed "CALIBRATION_FAILED"

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
    timer_ref = Process.send_after(self(), :check_calibration_status, 30_000)

    new_state = %{state | status: "PRE_CHECK1_STARTED", timer_ref: timer_ref}
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
    timer_ref = Process.send_after(self(), :check_calibration_status, 30_000)
    new_state = %{state | status: @pre_check2_started, timer_ref: timer_ref}
    {:reply, {:ok, new_state}, new_state}
  end

  def handle_call(:start_precheck_2, _from, state) do
    {:reply, {:error, :pending_precheck_1}, state}
  end

  def handle_call(:get_current_state, _from, state) do
    {:reply, state, state}
  end

  @impl GenServer
  def handle_info(%{"precheck1" => true}, %{timer_ref: timer_ref} = state) do
    clear_timer(timer_ref)
    {:noreply, %{state | precheck1: true, status: "PRE_CHECK1_SUCCEDED", timer_ref: nil}}
  end

  def handle_info(%{"precheck1" => _val}, %{timer_ref: timer_ref} = state) do
    clear_timer(timer_ref)
    {:noreply, %{state | precheck1: false, status: "PRE_CHECK1_FAILED", timer_ref: nil}}
  end

  def handle_info(%{"cartridgeStatus" => true}, state) do
    {:noreply, %{state | cartridge_status: true}}
  end

  def handle_info(%{"cartridgeStatus" => _}, state) do
    {:noreply, %{state | cartridge_status: false, status: @pre_check2_failed}}
  end

  def handle_info(%{"submergedInWater" => true}, %{timer_ref: timer_ref} = state) do
    clear_timer(timer_ref)

    new_state = %{
      state
      | submerged_in_water: true,
        status: "PRE_CHECK2_SUCCEEDED",
        timer_ref: nil
    }

    send(self(), :start_calibration)
    {:noreply, new_state}
  end

  def handle_info(%{"submergedInWater" => _}, state) do
    {:noreply, %{state | submerged_in_water: false, status: @pre_check2_failed}}
  end

  def handle_info(:start_calibration, %CalibrationSession{user_email: user_email} = state) do
    :ok = DeviceMessages.send(user_email, "calibrate")
    time_ref = Process.send_after(self(), :check_calibration_status, 100_000)

    new_state = %{state | status: "CALIBRATION_STARTED", timer_ref: time_ref}
    {:noreply, new_state}
  end

  def handle_info(%{"calibrated" => true}, %{timer_ref: timer_ref} = state) do
    clear_timer(timer_ref)
    {:noreply, %{state | calibrated: true, status: "CALIBRATION_SUCCEEDED", timer_ref: nil}}
  end

  def handle_info(%{"calibrated" => _}, state) do
    {:noreply, %{state | calibrated: false, status: @calibration_failed}}
  end

  @doc """
  Set calibration status as failed if precheck1 is not completed after 30 seconds
  """
  def handle_info(:check_calibration_status, %CalibrationSession{precheck1: nil} = state) do
    clear_timer(state.timer_ref)
    Logger.error("Calibration failed.\n Did not receive response from device after 30 seconds")

    new_state = %{state | status: @calibration_failed, timer_ref: nil}
    {:noreply, new_state}
  end

  def handle_info(:check_calibration_status, %{status: @pre_check2_started} = state) do
    clear_timer(state.timer_ref)
    Logger.error("Calibration failed.\n Did not receive response from device after 30 seconds")

    new_state = %{state | status: @calibration_failed, timer_ref: nil}
    {:noreply, new_state}
  end

  def handle_info(:check_calibration_status, %{status: "CALIBRATION_STARTED"} = state) do
    clear_timer(state.timer_ref)
    Logger.error("Calibration failed.\n Did not receive response from device after 100 seconds")

    new_state = %{state | status: @calibration_failed, timer_ref: nil}
    {:noreply, new_state}
  end

  def handle_info(:check_calibration_status, state) do
    Logger.info("Received :check_calibration_status with unmatched state #{inspect(state)}")
    {:noreply, state}
  end

  # catch any message that does not match and log to console
  def handle_info(msg, state) do
    Logger.warn("Received unknown message - #{inspect(msg)}")
    {:noreply, state}
  end

  defp clear_timer(timer_ref) when is_reference(timer_ref) do
    Process.cancel_timer(timer_ref)
  end

  defp clear_timer(_), do: :ok
end
