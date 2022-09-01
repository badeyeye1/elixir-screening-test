defmodule ElixirInterviewStarter.CalibrationSession do
  @moduledoc """
  A struct representing an ongoing calibration session, used to identify who the session
  belongs to, what step the session is on, and any other information relevant to working
  with the session.
  """

  @type t() :: %__MODULE__{
          calibrated: boolean(),
          cartridge_status: boolean(),
          precheck1: boolean(),
          status: String.t(),
          submerged_in_water: boolean(),
          timer_ref: reference(),
          user_email: String.t()
        }

  defstruct [
    :calibrated,
    :cartridge_status,
    :precheck1,
    :status,
    :submerged_in_water,
    :timer_ref,
    :user_email
  ]
end
