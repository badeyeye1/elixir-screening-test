defmodule ElixirInterviewStarter do
  @moduledoc """
  See `README.md` for instructions on how to approach this technical challenge.

  A singleton genserver responsible for creating calibration session managers and receiving
  async messages from a device and dispatching the message to the device's `SessionManager`
  """
  use GenServer
  require Logger

  alias ElixirInterviewStarter.CalibrationSession
  alias ElixirInterviewStarter.SessionManager

  def start_link(init_arg \\ []) do
    GenServer.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @spec start(user_email :: String.t()) :: {:ok, CalibrationSession.t()} | {:error, String.t()}
  @doc """
  Creates a new `CalibrationSession` for the provided user, starts a `GenServer` process
  for the session, and starts precheck 1.

  If the user already has an ongoing `CalibrationSession`, returns an error.
  """
  def start(user_email) do
    with {:ok, session_pid} <- SessionManager.start(user_email),
         %CalibrationSession{} = session <- SessionManager.start_precheck_1(session_pid) do
      {:ok, session}
    else
      {:error, {:already_started, _pid}} ->
        {:error, "Calibration already started"}
    end
  end

  @spec start_precheck_2(user_email :: String.t()) ::
          {:ok, CalibrationSession.t()} | {:error, String.t()}
  @doc """
  Starts the precheck 2 step of the ongoing `CalibrationSession` for the provided user.

  If the user has no ongoing `CalibrationSession`, their `CalibrationSession` is not done
  with precheck 1, or their calibration session has already completed precheck 2, returns
  an error.
  """
  def start_precheck_2(_user_email) do
    {:ok, %CalibrationSession{}}
  end

  @spec get_current_session(user_email :: String.t()) :: {:ok, CalibrationSession.t() | nil}
  @doc """
  Retrieves the ongoing `CalibrationSession` for the provided user, if they have one
  """
  def get_current_session(user_email) do
    with {:ok, session_pid} <- SessionManager.get_session_pid(user_email),
         %CalibrationSession{} = session <- SessionManager.get_current_state(session_pid) do
      {:ok, session}
    else
      _ -> {:ok, nil}
    end
  end

  # Server (Callbacks)
  @impl GenServer
  def init(state) do
    {:ok, state}
  end

  @impl GenServer
  def handle_info(
        {:device_msg, %{"user_email" => user_email} = payload},
        state
      ) do
    case SessionManager.get_session_pid(user_email) do
      {:ok, session_pid} ->
        Process.send(session_pid, payload, [])

      {:error, _} ->
        Logger.warn("received message from device without an active session")
    end

    {:noreply, state}
  end
end
