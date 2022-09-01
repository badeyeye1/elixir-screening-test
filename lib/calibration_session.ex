defmodule ElixirInterviewStarter.CalibrationSession do
  @moduledoc """
  A struct representing an ongoing calibration session, used to identify who the session
  belongs to, what step the session is on, and any other information relevant to working
  with the session.
  """

  @type t() :: %__MODULE__{
          cartridge_status: boolean(),
          precheck1: boolean(),
          status: String.t(),
          submerged_in_water: boolean(),
          user_email: String.t()
        }

  defstruct [:cartridge_status, :precheck1, :status, :submerged_in_water, :user_email]
end
